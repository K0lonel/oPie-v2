#Requires AutoHotkey v2.0+
#SingleInstance Force
Persistent
SendMode "Input"
SetWorkingDir A_ScriptDir
#Warn All, off
#Include <ShinsOverlayClass>
#Include <JSON>

; Setup Overlay
oPie_draw := ShinsOverlayClass(0, 0, A_ScreenWidth, A_ScreenHeight)
oPie_draw.SetAntialias(True)
ensureJSON(&settings)
loadAssets(wheel := loadWheel())

; State variables
isKeyDown := false
anchor_curX := 0, anchor_curY := 0

; --- Configuration Constants ---
pi := 3.1415926535
itemCount := settings["items"].Length
radius := settings["constants"]["radius"]
scale := settings["constants"]["scale"]

; Shape Control
flattenY := settings["constants"]["flattenY"]
itemGrowth := settings["constants"]["itemGrowth"]
squareSize := settings["constants"]["squareSize"]


SetTimer render, 1
render() {
  static rotation := 0
  static lastSelection := -1
  static selected := false
  if (isKeyDown)
  if (oPie_draw.BeginDraw()) {
    oPie_draw.GetMousePos(&curX, &curY)

    ; distance from center to cursor
    dx := curX - anchor_curX
    dy := curY - anchor_curY
    mouseAngle := Atan2(dx, dy)
    mouseAngle += 90
    rotation := rotation >= 360 ? 0 : (rotation += 0.5)

    stepAngle := 360 / itemCount
    global selectIndex := Mod(Round(mouseAngle / stepAngle), itemCount)

    effectiveRadius := (radius + (itemCount * itemGrowth)) * scale
    radX := effectiveRadius
    radY := effectiveRadius * flattenY


    loop itemCount {
      i := A_Index - 1
      selected := (i == selectIndex)

      angleDeg := (i * stepAngle) - 90 ; -90 because we want to start at top
      angleRad := angleDeg * (pi / 180)
      targetX := Floor(anchor_curX + Cos(angleRad) * radX)
      targetY := Floor(anchor_curY + Sin(angleRad) * radY)

      drawSize := squareSize
      global select := !inRegionCircle(curX, curY, anchor_curX, anchor_curY, 50 * scale)
      if (selected) {
        if(select) {
          drawSize := squareSize * 1.5
        
          oPie_draw.DrawImage("pointer_" settings["items"][A_Index]["icon"] ,
          anchor_curX + 10 * scale * Cos((mouseAngle - 90) * (pi / 180)),
          anchor_curY + 10 * scale * Sin((mouseAngle - 90) * (pi / 180)),
          250 * scale, 250 * scale, , , , , 0.5, true, mouseAngle)
        }

        oPie_draw.DrawImage("circle_" settings["items"][A_Index]["icon"] , anchor_curX, anchor_curY, 100 * scale, 100 * scale, , , , , 0.5, true, rotation)
        oPie_draw.DrawImage("glow_" settings["items"][A_Index]["icon"] , anchor_curX, anchor_curY, 200 * scale, 200 * scale, , , , , 0.5, true, rotation)
      }
      ; oPie_draw.DrawImage("oglow_" settings["items"][A_Index]["icon"], targetX, targetY, drawSize, drawSize, , , , , 0.5, true)
      oPie_draw.DrawImage(settings["items"][A_Index]["icon"], targetX, targetY, drawSize, drawSize, , , , , 0.8, true)
    }
    ; Debug Text
    ; oPie_draw.DrawText(select, curX, curY, 20, 0xFF00FF00)
    oPie_draw.EndDraw()
  }
}

!d:: {
  global isKeyDown, anchor_curX, anchor_curY

  if (!isKeyDown) {
    oPie_draw.GetMousePos(&anchor_curX, &anchor_curY)
  }
  isKeyDown := true
}

!d Up:: {
  global isKeyDown, select
  
  isKeyDown := false

  if(select)
    RunScript(settings["items"][selectIndex+1]["script"])
  oPie_draw.Clear()
}

Atan2(x, y) {
  if (x = 0)
    return (y > 0 ? 90 : (y < 0 ? -90 : 0))
  angle := ATan(y / x) * (180 / pi)
  return (x < 0 ? angle + 180 : (y < 0 ? angle + 360 : angle))
}

getDistance(x1, y1, x2, y2) {
  return Sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
}

inRegionRect(mx, my, x, y, w, h) {
  return (mx >= x && mx <= (x + w) && my >= y && my <= (y + h))
}

inRegionCircle(mx, my, circle_x, circle_y, r) {
  return ((mx - circle_x) ** 2 + (my - circle_y) ** 2) <= (r ** 2)
}

hsl2rgb(h, s, l) {
  if (s == 0) {
    return { r: l, g: l, b: l }
  }
  
  q := (l < 0.5) ? (l * (1 + s)) : (l + s - l * s)
  p := 2 * l - q

  r := hue2rgb(p, q, h + 1 / 3)
  g := hue2rgb(p, q, h)
  b := hue2rgb(p, q, h - 1 / 3)
  return { r: r, g: g, b: b }
}

hue2rgb(p, q, t) {
  if (t < 0)
    t += 1
  if (t > 1)
    t -= 1
  if (t < 1 / 6)
    return p + (q - p) * 6 * t
  if (t < 1 / 2)
    return q
  if (t < 2 / 3)
    return p + (q - p) * (2 / 3 - t) * 6
  return p
}

rgb2hsl(r, g, b) {
  maxVal := Max(r, g, b)
  minVal := Min(r, g, b)
  l := (maxVal + minVal) / 2

  if (maxVal == minVal) {
    h := 0
    s := 0
  } else {
    d := maxVal - minVal
    s := (l > 0.5) ? d / (2 - maxVal - minVal) : d / (maxVal + minVal)

    if (maxVal == r)
      h := (g - b) / d + (g < b ? 6 : 0)
    else if (maxVal == g)
      h := (b - r) / d + 2
    else
      h := (r - g) / d + 4
    h /= 6
  }
  return { h: h, s: s, l: l }
}

loadWheel() {
  ensureFolderStructure(targetFolder := A_ScriptDir "\assets\wheel")
  wheel := Map()

  Loop Files, targetFolder "\*.*" {
    SplitPath(A_LoopFileName, , , , &nameNoExt)
    wheel[StrLower(nameNoExt)] := A_LoopFileFullPath
  }
    
  return wheel
}

loadAssets(assetsMap) {
  ensureFolderStructure(targetFolder := A_ScriptDir "\assets\icons")

  Loop Files, targetFolder "\*.*" {
    SplitPath(A_LoopFileName, , , , &itemName)
    cleanItemName := StrLower(itemName)
    getDominantVibrantColor(A_LoopFileFullPath, &color)
    
    CreateTintedVariant(A_LoopFileFullPath, cleanItemName, 1, 1, 1) ; add original one
    for key, assetPath in assetsMap {
      CreateTintedVariant(assetPath, key "_" cleanItemName, color.r, color.g, color.b)
    }
  }
}

ensureFolderStructure(targetFolder) {
  if !DirExist(targetFolder) {
    try {
      DirCreate(targetFolder)
    } catch as err {
      Throw Error("Could not create directory.`n" targetFolder, -1, err.Message)
    }
    Throw Error("Folder is empty.`n" targetFolder, -1)
  }
  return true
}

ensureJSON(&settings) {
  if(!FileExist("settings.json"))
    settings := createSettings()
  settings := JSON.LoadFile("settings.json")
}

createSettings() {
  constants := Map(), items := Array()
  obj := Map("constants", constants, "items", items)
  obj["constants"]["radius"] := 150
  obj["constants"]["scale"] := 1
  obj["constants"]["flattenY"] := 0.95
  obj["constants"]["itemGrowth"] := 5
  obj["constants"]["squareSize"] := 64
  
  obj["items"].Push(Map("icon", "star", "script", "msgbox 'You can write any ahk code you want!'"))
  obj["items"].Push(Map("icon", "diamond", "script", "msgbox 'In line code definitions!'"))
  JSON.DumpFile(obj, "settings.json", true)
  return obj
}

RunScript(code) {
try {
    shell := ComObject("WScript.Shell")

    if A_IsCompiled {
      cmd := '"' A_AhkPath '" /script /ErrorStdOut *'
    } else {
      cmd := '"' A_AhkPath '" /ErrorStdOut *'
    }

    exec := shell.Exec(cmd)
    exec.StdIn.Write(code)
    exec.StdIn.Close()
  } catch as err {
    MsgBox("Error executing dynamic code:`n" err.Message)
  }
}

GetDominantVibrantColor(imagePath, &color, alpha := 255) {
  ; 1. Load the image
  pBitmap := 0
  DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", imagePath, "Ptr*", &pBitmap)
  if !pBitmap
    return { hex: "0xFFFFFFFF", r: 1, g: 1, b: 1 }

  ; 2. Create Thumbnail (Performance optimization)
  w := 25, h := 25
  pThumb := 0
  DllCall("gdiplus\GdipGetImageThumbnail", "ptr", pBitmap, "uint", w, "uint", h, "ptr*", &pThumb, "ptr", 0, "ptr", 0)
  DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)

  sumR := 0, sumG := 0, sumB := 0, count := 0

  ; 3. Iterate pixels
  loop w {
    x := A_Index - 1
    loop h {
      y := A_Index - 1
      argb := 0
      DllCall("gdiplus\GdipBitmapGetPixel", "ptr", pThumb, "int", x, "int", y, "uint*", &argb)

      r := ((argb >> 16) & 0xFF) / 255.0
      g := ((argb >> 8) & 0xFF) / 255.0
      b := (argb & 0xFF) / 255.0

      ; Filter out muddy colors
      hsl := rgb2hsl(r, g, b)
      if (hsl.s > 0.15 && hsl.l > 0.10 && hsl.l < 0.90) {
        sumR += r
        sumG += g
        sumB += b
        count++
      }
    }
  }
  DllCall("gdiplus\GdipDisposeImage", "ptr", pThumb)

  if (count == 0)
    return { hex: "0xFFFFFFFF", r: 1, g: 1, b: 1 }

  ; 4. Average and Boost
  avgR := sumR / count
  avgG := sumG / count
  avgB := sumB / count

  finalHsl := rgb2hsl(avgR, avgG, avgB)
  finalS := Max(finalHsl.s, 0.60)
  finalL := Max(0.40, Min(finalHsl.l, 0.70))

  ; Get final RGB Floats (0.0 - 1.0)
  resRGB := hsl2rgb(finalHsl.h, finalS, finalL)

  ; 5. FORMAT OUTPUT
  ; Convert floats to 0-255 Integers
  intR := Floor(resRGB.r * 255)
  intG := Floor(resRGB.g * 255)
  intB := Floor(resRGB.b * 255)

  ; Create the Hex String (0xAARRGGBB)
  hexColor := Format("0x{:02X}{:02X}{:02X}{:02X}", alpha, intR, intG, intB)

  ; Return everything you might need
  color := {
    hex: hexColor,
    r: resRGB.r,
    g: resRGB.g,
    b: resRGB.b
  }
}

CreateTintedVariant(sourcePath, customKey, tintR, tintG, tintB) {
  if !FileExist(sourcePath)
    return false

  ; 1. Load Source
  bm := 0
  DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", sourcePath, "Ptr*", &bm)
  if (!bm)
    return false

  w := 0, h := 0
  DllCall("gdiplus\GdipGetImageWidth", "Ptr", bm, "Uint*", &w)
  DllCall("gdiplus\GdipGetImageHeight", "Ptr", bm, "Uint*", &h)

  ; 2. Create Canvas
  newBm := 0
  DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", 0, "int", 0x26200A, "Ptr", 0, "Ptr*", &
    newBm)
  g := 0
  DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", newBm, "Ptr*", &g)

  ; 3. Tint Matrix
  ia := 0
  DllCall("gdiplus\GdipCreateImageAttributes", "Ptr*", &ia)
  matrix := Buffer(100, 0)
  NumPut("float", tintR, matrix, 0)
  NumPut("float", tintG, matrix, 24)
  NumPut("float", tintB, matrix, 48)
  NumPut("float", 1.0, matrix, 72)
  NumPut("float", 1.0, matrix, 96)

  DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "Ptr", ia, "int", 1, "int", 1, "Ptr", matrix, "Ptr", 0, "int",
    0)
  DllCall("gdiplus\GdipDrawImageRectRect", "Ptr", g, "Ptr", bm, "float", 0, "float", 0, "float", w, "float", h,
    "float", 0, "float", 0, "float", w, "float", h, "int", 2, "Ptr", ia, "Ptr", 0, "Ptr", 0)

  ; 4. Lock & Prepare for D2D
  rect := Buffer(16, 0)
  NumPut("int", w, rect, 8), NumPut("int", h, rect, 12)
  bmdata := Buffer(32, 0)
  DllCall("Gdiplus\GdipBitmapLockBits", "Ptr", newBm, "Ptr", rect, "uint", 3, "int", 0x26200A, "Ptr", bmdata)
  scan := NumGet(bmdata, 16, "Ptr")

  ; --- MEMORY INJECTION INTO CUSTOM KEY ---

  ; Delete the OLD tinted version if it exists to free memory
  if (oPie_draw.imageCache.Has(customKey)) {
    if (oPie_draw.imageCache[customKey]["p"] && oPie_draw.vTable(oPie_draw.imageCache[customKey]["p"], 2)) {
      DllCall(oPie_draw.vTable(oPie_draw.imageCache[customKey]["p"], 2), "ptr", oPie_draw.imageCache[customKey][
        "p"])
    }
    oPie_draw.imageCache.Delete(customKey)
  }

  pData := DllCall("GlobalAlloc", "uint", 0x40, "ptr", 16 + ((w * h) * 4), "ptr")
  DllCall(oPie_draw._cacheImage, "Ptr", pData, "Ptr", scan, "int", w, "int", h, "uchar", 255, "int")

  d2dBitmap := 0
  d2dProps := Buffer(64, 0)
  NumPut("uint", 28, d2dProps, 0), NumPut("uint", 1, d2dProps, 4)

  if (oPie_draw.bits) {
    bfSize := Buffer(64)
    NumPut("uint", w, bfSize, 0), NumPut("uint", h, bfSize, 4)
    DllCall(oPie_draw.vTable(oPie_draw.renderTarget, 4), "ptr", oPie_draw.renderTarget, "int64", NumGet(bfSize, 0,
      "int64"), "ptr", pData, "uint", 4 * w, "ptr", d2dProps, "Ptr*", &d2dBitmap)
  } else {
    DllCall(oPie_draw.vTable(oPie_draw.renderTarget, 4), "ptr", oPie_draw.renderTarget, "uint", w, "uint", h, "ptr",
    pData, "uint", 4 * w, "ptr", d2dProps, "Ptr*", &d2dBitmap)
  }

  ; STORE UNDER CUSTOM KEY
  if (d2dBitmap)
    oPie_draw.imageCache[customKey] := Map("p", d2dBitmap, "w", w, "h", h)

  ; Cleanup
  DllCall("Gdiplus\GdipBitmapUnlockBits", "Ptr", newBm, "Ptr", bmdata)
  DllCall("gdiplus\GdipDisposeImageAttributes", "Ptr", ia)
  DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
  DllCall("gdiplus\GdipDisposeImage", "ptr", newBm)
  DllCall("gdiplus\GdipDisposeImage", "ptr", bm)

  return true
}

ApplyTintManual(image, tintR, tintG, tintB) {
  ; 1. Load the GDI+ Bitmap from file
  bm := 0
  DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", image, "Ptr*", &bm)
  if (!bm) {
    oPie_draw.Err("ApplyTintManual: Error", "Could not load image: " image)
    return false
  }

  ; 2. Get Dimensions
  w := 0, h := 0
  DllCall("gdiplus\GdipGetImageWidth", "Ptr", bm, "Uint*", &w)
  DllCall("gdiplus\GdipGetImageHeight", "Ptr", bm, "Uint*", &h)

  ; 3. Create a blank canvas (new Bitmap) to draw the tinted result onto
  newBm := 0
  DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", 0, "int", 0x26200A, "Ptr", 0, "Ptr*", &
    newBm)

  ; Get Graphics context for the new bitmap
  g := 0
  DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", newBm, "Ptr*", &g)

  ; 4. Create ImageAttributes and apply the Color Matrix (Replaces the slow Pixel Loop)
  ia := 0
  DllCall("gdiplus\GdipCreateImageAttributes", "Ptr*", &ia)

  ; Color Matrix (5x5 matrix to multiply R, G, B channels)
  ; Values are floats. Format:
  ; [ R, 0, 0, 0, 0 ]
  ; [ 0, G, 0, 0, 0 ]
  ; [ 0, 0, B, 0, 0 ]
  ; [ 0, 0, 0, A, 0 ]
  ; [ 0, 0, 0, 0, 1 ]
  matrix := Buffer(100, 0)
  NumPut("float", tintR, matrix, 0)   ; Red Scale
  NumPut("float", tintG, matrix, 24)  ; Green Scale
  NumPut("float", tintB, matrix, 48)  ; Blue Scale
  NumPut("float", 1.0, matrix, 72)  ; Alpha Scale
  NumPut("float", 1.0, matrix, 96)  ; 1

  DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "Ptr", ia, "int", 1, "int", 1, "Ptr", matrix, "Ptr", 0, "int",
    0)

  ; Draw the original image onto the new bitmap using the Tint Matrix
  DllCall("gdiplus\GdipDrawImageRectRect", "Ptr", g, "Ptr", bm, "float", 0, "float", 0, "float", w, "float", h,
    "float", 0, "float", 0, "float", w, "float", h, "int", 2, "Ptr", ia, "Ptr", 0, "Ptr", 0)

  ; 5. Lock bits of the NEW tinted bitmap to prepare for Direct2D injection
  rect := Buffer(16, 0)
  NumPut("int", w, rect, 8), NumPut("int", h, rect, 12)
  bmdata := Buffer(32, 0)
  DllCall("Gdiplus\GdipBitmapLockBits", "Ptr", newBm, "Ptr", rect, "uint", 3, "int", 0x26200A, "Ptr", bmdata)
  scan := NumGet(bmdata, 16, "Ptr")

  ; -------------------------------------------------------------------------
  ; DIRECT MEMORY INJECTION (Bypassing File Save/Load)
  ; This logic copies how ShinsOverlayClass converts GDI+ -> Direct2D internally
  ; -------------------------------------------------------------------------

  ; Clear existing cache for this image if it exists
  if (oPie_draw.imageCache.Has(image)) {
    if (oPie_draw.imageCache[image]["p"] && oPie_draw.vTable(oPie_draw.imageCache[image]["p"], 2)) {
      DllCall(oPie_draw.vTable(oPie_draw.imageCache[image]["p"], 2), "ptr", oPie_draw.imageCache[image]["p"])
    }
    oPie_draw.imageCache.Delete(image)
  }

  ; Allocate global memory for Direct2D (Logic from ShinsOverlayClass source )
  pData := DllCall("GlobalAlloc", "uint", 0x40, "ptr", 16 + ((w * h) * 4), "ptr")

  ; Use the Overlay Class's internal MCode to copy/format pixels (Logic from source )
  ; We access the hidden _cacheImage method pointer directly
  DllCall(oPie_draw._cacheImage, "Ptr", pData, "Ptr", scan, "int", w, "int", h, "uchar", 255, "int")

  ; Create the D2D Bitmap from memory
  d2dBitmap := 0
  d2dProps := Buffer(64, 0)
  NumPut("uint", 28, d2dProps, 0)
  NumPut("uint", 1, d2dProps, 4)

  ; Call CreateBitmap on the RenderTarget (VTable index 4)
  if (oPie_draw.bits) { ; 64-bit logic
    bfSize := Buffer(64)
    NumPut("uint", w, bfSize, 0)
    NumPut("uint", h, bfSize, 4)
    DllCall(oPie_draw.vTable(oPie_draw.renderTarget, 4), "ptr", oPie_draw.renderTarget, "int64", NumGet(bfSize, 0,
      "int64"), "ptr", pData, "uint", 4 * w, "ptr", d2dProps, "Ptr*", &d2dBitmap)
  } else { ; 32-bit logic
    DllCall(oPie_draw.vTable(oPie_draw.renderTarget, 4), "ptr", oPie_draw.renderTarget, "uint", w, "uint", h, "ptr",
    pData, "uint", 4 * w, "ptr", d2dProps, "Ptr*", &d2dBitmap)
  }

  ; Update the Cache with the new D2D Bitmap
  if (d2dBitmap)
    oPie_draw.imageCache[image] := Map("p", d2dBitmap, "w", w, "h", h)

  ; -------------------------------------------------------------------------
  ; CLEANUP
  ; -------------------------------------------------------------------------
  DllCall("Gdiplus\GdipBitmapUnlockBits", "Ptr", newBm, "Ptr", bmdata)
  DllCall("gdiplus\GdipDisposeImageAttributes", "Ptr", ia)
  DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
  DllCall("gdiplus\GdipDisposeImage", "ptr", newBm)
  DllCall("gdiplus\GdipDisposeImage", "ptr", bm)

  return true
}

$^r:: Reload