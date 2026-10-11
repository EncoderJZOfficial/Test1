import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.view.Gravity"

-- Android bindings
Context = luajava.bindClass("android.content.Context")
PixelFormat = luajava.bindClass("android.graphics.PixelFormat")
WindowManagerLayoutParams = luajava.bindClass("android.view.WindowManager$LayoutParams")
Build = luajava.bindClass("android.os.Build")
MotionEvent = luajava.bindClass("android.view.MotionEvent")

wm = activity.getSystemService(Context.WINDOW_SERVICE)

-- ===== State =====
local jaraz = true
local hsl = {}       -- base results
local locations = {} -- saved locations
local mainView, lp

-- ===== Helpers =====
local function dp2px(dp)
  local density = activity.getResources().getDisplayMetrics().density
  return math.floor(dp * density   0.5)
end

-- ===== GG search =====
function initBaseSearch()
  pcall(function()
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.setVisible(false)
    -- QWORD search
    gg.searchNumber("4522334597891133275", gg.TYPE_QWORD)
    local t = gg.getResults(12)
    for i, v in ipairs(t) do
      v.address = v.address - 0x44
      v.flags = gg.TYPE_FLOAT
    end
    gg.addListItems(t)
    gg.loadResults(gg.getListItems())
    gg.clearList()
    -- Fuzzy search
    gg.searchFuzzy("0", gg.SIGN_FUZZY_NOT_EQUAL, gg.TYPE_FLOAT, 0, -1, 0)
    t = gg.getResults(12)
    for i, v in ipairs(t) do
      v.address = v.address   0x4
      v.flags = gg.TYPE_FLOAT
    end
    gg.addListItems(t)
    gg.loadResults(gg.getListItems())
    gg.clearList()
    hsl = gg.getResults(12)
    gg.toast("Search done")
  end)
end

function getPosition()
  if not hsl or #hsl == 0 then initBaseSearch() end
  local ok, res = pcall(function()
    gg.clearResults()
    local addr = hsl[#hsl].address   0x7c
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local X = gg.getResults(1); gg.clearResults()
    addr = X[1].address - 0x8
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local Y = gg.getResults(1); gg.clearResults()
    addr = X[1].address - 0x4
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local Z = gg.getResults(1); gg.clearResults()
    return {x=X[1].value, y=Y[1].value, z=Z[1].value}
  end)
  if ok then return res else return nil end
end

function teleport(loc)
  if not loc then return end
  if not hsl or #hsl == 0 then initBaseSearch() end
  pcall(function()
    gg.clearResults()
    local addr = hsl[#hsl].address   0x7c
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local X = gg.getResults(1); gg.clearResults()
    addr = X[1].address - 0x8
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local Y = gg.getResults(1); gg.clearResults()
    addr = X[1].address - 0x4
    gg.searchAddress("B20", nil, gg.TYPE_FLOAT, gg.SIGN_NOT_EQUAL, addr, addr)
    local Z = gg.getResults(1); gg.clearResults()
    X[1].value = loc.x
    Y[1].value = loc.y
    Z[1].value = loc.z
    gg.setValues(X); gg.setValues(Y); gg.setValues(Z)
    gg.toast(string.format("Teleported → %s", loc.name))
  end)
end

-- ===== UI =====
local function refreshLocationButtons(row)
  -- удаляем старые кнопки сохранённых локаций
  for i=#row.getChildCount()-1,5,-1 do
    row.removeViewAt(i)
  end
  for i, loc in ipairs(locations) do
    local btn = Button(activity)
    btn.setText(loc.name)
    btn.setLayoutParams(LinearLayout.LayoutParams(dp2px(80), dp2px(45)))
    btn.setTextSize(12)
    btn.setOnClickListener(function() teleport(loc) end)
    row.addView(btn)
  end
end

function createMainMenu()
  activity.runOnUiThread(function()
    local ids = {}
    mainView = loadlayout({
      LinearLayout,
      orientation="vertical",
      layout_width="wrap_content",
      layout_height="wrap_content",
      padding="8dp",
      background="#CC000000",
      { TextView, text="Teleport Menu", textColor=0xFFFFFFFF, textSize="16sp",
        gravity="center", layout_marginBottom="6dp", id="dragTitle" },
      { LinearLayout, orientation="horizontal", id="btnRow",
        { Button, text="START", id="startBtn", layout_width="80dp", layout_height="45dp", background="#003300", textColor=0xFFFFFFFF },
        { Button, text="ADD", id="addBtn", layout_width="80dp", layout_height="45dp", layout_marginLeft="4dp", background="#0066CC", textColor=0xFFFFFFFF },
        { Button, text="DELETE", id="delBtn", layout_width="80dp", layout_height="45dp", layout_marginLeft="4dp", background="#660000", textColor=0xFFFFFFFF },
        { Button, text="EXIT", id="exitBtn", layout_width="80dp", layout_height="45dp", layout_marginLeft="4dp", background="#330000", textColor=0xFFFFFFFF }
      }
    }, ids)

    lp = WindowManagerLayoutParams()
    lp.width = WindowManagerLayoutParams.WRAP_CONTENT
    lp.height = WindowManagerLayoutParams.WRAP_CONTENT
    lp.format = PixelFormat.TRANSLUCENT
    lp.gravity = Gravity.CENTER
    lp.type = (Build.VERSION.SDK_INT >= 26) and 2038 or 2002
    lp.flags = WindowManagerLayoutParams.FLAG_NOT_FOCUSABLE
               WindowManagerLayoutParams.FLAG_LAYOUT_IN_SCREEN
               WindowManagerLayoutParams.FLAG_LAYOUT_NO_LIMITS
               WindowManagerLayoutParams.FLAG_NOT_TOUCH_MODAL
    wm.addView(mainView, lp)

    -- Drag
    local sx, sy, ox, oy
    ids.dragTitle.setOnTouchListener(function(v,e)
      local a = e.getAction()
      if a==MotionEvent.ACTION_DOWN then sx,sy=e.getRawX(),e.getRawY(); ox,oy=lp.x or 0, lp.y or 0; return true
      elseif a==MotionEvent.ACTION_MOVE then lp.x=ox (e.getRawX()-sx); lp.y=oy (e.getRawY()-sy); wm.updateViewLayout(mainView,lp); return true end
      return false
    end)

    -- START
    ids.startBtn.onClick = function() coroutine.wrap(initBaseSearch)() end

    -- ADD
    ids.addBtn.onClick = function()
      local pos = getPosition()
      if not pos then gg.toast("Failed to get position") return end
      local t = gg.prompt({"Name of save"}, nil, {"text"})
      if t and t[1] and #t[1]>0 then
        local loc = {name=t[1], x=pos.x, y=pos.y, z=pos.z}
        table.insert(locations, loc)
        refreshLocationButtons(ids.btnRow)
        gg.toast("Saved: "..t[1])
      end
    end

    -- DELETE
    ids.delBtn.onClick = function() gg.toast("Hold a saved button to delete it") end

    -- EXIT
    ids.exitBtn.onClick = function()
      pcall(function() if mainView then wm.removeView(mainView) end end)
      jaraz=false
      os.exit()
    end
  end)
end

-- ===== Start =====
createMainMenu()

while jaraz do
  gg.sleep(100)
end