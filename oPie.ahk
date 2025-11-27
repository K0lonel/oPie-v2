#Requires AutoHotkey v2.0+
#SingleInstance Force
Persistent
SendMode "Input"
SetWorkingDir A_ScriptDir
#Include <ShinsOverlayClass>

oPie_draw := ShinsOverlayClass(0, 0, A_ScreenWidth, A_ScreenHeight)
oPie_draw.SetAntialias(True)
pi := 3.14159, isKeyDown := false, scale := 1

SetTimer render, 1

render() {
    static rotation := 0
    if (oPie_draw.BeginDraw() && isKeyDown) {
        oPie_draw.GetMousePos(&curX, &curY)
        rotationAngle := getRotAngle(curX, curY, anchor_curX, anchor_curY)
        rotation := rotation >= 360 ? 0 : (rotation += 0.5)
        
        oPie_draw.DrawImage(A_ScriptDir "\assets\circle.png", anchor_curX, anchor_curY, 100*scale, 100*scale, , , , , 0.5, 1, rotation)
        oPie_draw.DrawImage(A_ScriptDir "\assets\glow.png", anchor_curX, anchor_curY, 200*scale, 200*scale, , , , , 0.5, 1, rotation)
        oPie_draw.DrawImage(A_ScriptDir "\assets\pointer.png", anchor_curX + 60*scale*Cos(rotationAngle * (pi / 180)), anchor_curY + 60*scale*Sin(rotationAngle * (pi / 180)), 250*scale, 250*scale, , , , , 0.5, 1, rotationAngle+90)
        oPie_draw.EndDraw()
    }
}

F1::{
    oPie_draw.ApplyTintManual(A_ScriptDir "\assets\circle.png", 1, 0, 0)
    oPie_draw.ApplyTintManual(A_ScriptDir "\assets\glow.png", 1, 0, 0)
    oPie_draw.ApplyTintManual(A_ScriptDir "\assets\pointer.png", 1, 0, 0)
}

!d:: {
    global isKeyDown, anchor_curX, anchor_curY
    
    if (!isKeyDown) {
        oPie_draw.GetMousePos(&anchor_curX, &anchor_curY)
    }
    isKeyDown := true
}

!d Up:: {
    global isKeyDown
    
    isKeyDown := false
    oPie_draw.Clear()
}

getRotAngle(mx, my, x, y) {
    return Atan2(mx - x, my - y)
}

Atan2(x, y) {    
    if (x = 0)
        return (y > 0 ? 90 : (y < 0 ? -90 : 0))
    angle := ATan(y / x) * (180 / pi)
    return (x < 0 ? angle + 180 : (y < 0 ? angle + 360 : angle))
}

$^r::Reload