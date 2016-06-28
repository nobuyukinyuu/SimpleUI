Import common

Class CircularPicker Extends PushButton
  Protected
	Const SQ22:Float = 0.70710678118654752440084436210485  'Sqrt(2)/2

	Const INDICATOR_GFX:String = "0011110001222210120000211200002112000021120000210122221000111100"
	Field indicator_img:Image = CreateImage(8, 8,, Image.MidHandle)

	Field hue:Float 'Hue color
	Field indicatorX:Float, indicatorY:Float  'Saturation, Luminosity

  Public

  	Field Dragging:Int = 0   'drag flag:  0=None; 1=Hue; 2=Sat/Lum
		Const DRAG_HUE = 1
		Const DRAG_XY = 2
		Const DRAG_NONE = 0

  		
	Method New(x:Float, y:Float, size:Float, Input:InputPointer)
		Super.New(x + size / 2, y + size / 2, size, size, Input)
		
		GenIndicatorImage()
	End Method

	Method GenIndicatorImage:Void()
		'Generate indicator image.
		Local px:= New IntStack
		For Local i:Int = 0 Until 64
			Select INDICATOR_GFX[i]
				Case 48  'Trans
				px.Push(0)
				
				Case 49  'Black
				px.Push($FF000000)
					
				Case 50  'White
				px.Push($FFFFFFFF)
			End Select

		Next
		 indicator_img.WritePixels(px.ToArray(), 0, 0, 8, 8, 0, 8)
	End Method
	
	Method Poll:Void(xOffset:Float = 0, yOffset:Float = 0)
		Super.Poll(xOffset, yOffset)
		
		
		Local inR:Float = Min(w, h) * 0.375
		Local sqpos:Float = inR * SQ22  'offset
		Local sqw:Float = inR * 2 * SQ22

		
		If Input.Hit() And UI.WithinRect(Input.x, Input.y, x - w / 2.0, y - h / 2.0, w, h)			
			If Not UI.WithinRect(Input.x, Input.y, x - sqpos, y - sqpos, sqw, sqw)
				Dragging = DRAG_HUE
			Else
				Dragging = DRAG_XY
			End If
		End If

				
		If Input.Down And Dragging = DRAG_HUE
			hue = (Int(ATan2(Input.y - y, Input.x - x) + 360) Mod 360) / 360.0
		ElseIf Input.Down And Dragging = DRAG_XY
			indicatorX = UI.Normalize(Input.x, x - sqpos, x - sqpos + sqw)
			indicatorY = UI.Normalize(Input.y, y - sqpos, y - sqpos + sqw)
		End If
		
		If Input.Up()
			Dragging = 0
		End If
	End Method
	
	Method Render:Void(xOffset:Float = 0, yOffset:Float = 0)
	If Not Visible Then Return
		Local rgb:Int[3]
		Local outR:Float = w * 0.5
		Local inR:Float = w * 0.375
		Local midR:Float = w * 0.4375

		'Draw shadow.
		SetAlpha(0.25)
		SetColor(0, 0, 0)
		DrawCircle(x, y + 5.5, outR)
		SetAlpha(1)
		
		'Draw the wheel.		
		For Local i:Float = 0 Until 360 Step 0.5
			rgb = HSLtoRGB(float(i) / 360.0, 1, 0.5)
			SetColor(rgb[0], rgb[1], rgb[2])
			DrawLine(x + Cos(i) * inR, y + Sin(i) * inR, x + Cos(i + 15) * outR, y + Sin(i + 15) * outR)
			SetColor(255, 255, 255)
		Next
			'DrawText(Int(ATan2(MouseY() -x, MouseX() -y) + 360) Mod 360, 128, 128, 0.5, 0.5)
			SetColor(64, 64, 64)
			DrawArc(x + midR * Cos(hue * 360), y + midR * Sin(hue * 360), w * 0.0625, w * 0.0625,,, 27)
			SetColor(255, 255, 255)
			
		'Draw the square.
		Local sqw:Float = inR * 2 * SQ22
		Local sqpos:Int = inR * SQ22
		For Local yy:Int = 0 Until sqw
		For Local xx:Int = 0 Until sqw
			Local gamut:Float = 1 - (xx / sqw) / 2   'range of luminance values to express approaches 0 as saturation reaches 1
'			rgb = HSLtoRGB(0, float(xx) / sqw, 1.0 - float(yy ) / sqw)
			rgb = HSLtoRGB(hue, float(xx) / sqw, 1.0 - UI.Lerp(0, gamut, yy / sqw) - (1 - gamut))
			SetColor(rgb[0], rgb[1], rgb[2])
			DrawPoint(x + xx - sqpos, y + yy - sqpos)
			SetColor(255, 255, 255)
		Next
		Next
		
		'draw outlines.
		SetColor(64, 64, 64)
		DrawRectOutline(x - sqpos, y - sqpos, sqw, sqw)
		DrawArc(x, y, inR, inR,,, 27)
		DrawArc(x, y, outR, outR,,, 27)
		SetColor(255, 255, 255)
		

		'Draw indicator.
		DrawImage(indicator_img, Int(x - sqpos + indicatorX * sqw), Int(y - sqpos + indicatorY * sqw))
	End Method

	'Summary:  Gets debug HSL values from the picker.
	Method GetHSL:Float[] ()
		Local gamut:Float = 1 - indicatorX / 2   'range of luminance values to express approaches 0 as saturation reaches 1
		Local L:Float = 1.0 - UI.Lerp(0, gamut, indicatorY) - (1 - gamut)
		Return[hue, indicatorX, L]
	End Method
	
	'Summary:  Gets the picker's current RGB balues.
	Method GetRGB:Int[] ()
		Local hsl:= GetHSL()
		Return HSLtoRGB(hsl[0], hsl[1], hsl[2])
	End Method

	'Summary:  Sets the picker's current RGB balues.
	Method SetRGB:Void(r:Int, g:Int, b:Int)
		Local hsv:= RGBtoHSV(r, g, b)
		
		'Fix some values before plugging them in.
		If hsv[0] = 1.0 Then hsv[0] = 0  'hsvtoRGB doesn't like hue values of 1.0.
		If hsv[0] <> hsv[0] Then hsv[0] = 0  'hsvtoRGB doesn't like hue values of undefined.
		
		
		hue = hsv[0]
		indicatorX = hsv[1]
		indicatorY = 1 - hsv[2]
	End Method
	


'Summary:  Draws an arc.  With the default arguments, this function can also draw elipse outlines.
Function DrawArc:Void(x:Float, y:Float, xRad:Float, yRad:Float, aStart:Float = 0.0, aEnd:Float = 360.0, segments:Int = 8)
	Local x1:Float = x + ( Cos( aStart ) * xRad )
	Local y1:Float = y - ( Sin( aStart ) * yRad )
	Local x2:Float
	Local y2:Float
	Local div:Float  = ( aEnd - aStart ) / segments
	For Local i:Int = 1 To segments
		x2 = x + ( Cos( aStart + ( i * div )) * xRad )
		y2 = y - ( Sin( aStart + ( i * div )) * yRad )
			DrawLine(x1, y1, x2, y2)
		x1 = x2
		y1 = y2
	Next
End Function

Function DrawRectOutline:Void(x:Float, y:Float, w:Float, h:Float)
	DrawLine(x, y, x + w, y)
	DrawLine(x,y,x,y+h)
	DrawLine(x,y+h,x+w,y+h)
	DrawLine(x+w,y,x+w,y+h)
End Function


Function Round:Int(a:Float)
	Return int(Floor(a + 0.5))
End Function

' colour conversions (hsl is range 0-1, return is RGB as a single int)
' Monkey conversion of http://www.geekymonkey.com/Programming/CSharp/RGB2HSL_HSL2RGB.htm
' shamelessly stolen and altered from the Diddy framework......
Function HSLtoRGB:Int[] (hue:Float, saturation:Float, luminance:Float)
	Local r:Float = luminance, g:Float = luminance, b:Float = luminance
	Local v:Float = 0
	If luminance <= 0.5 Then
		v = luminance * (1.0 + saturation)
	Else
		v = luminance + saturation - luminance * saturation
	End
	If v > 0 Then
		Local m:Float = luminance + luminance - v
		Local sv:Float = (v - m) / v
		hue *= 6
		Local sextant:Int = Int(hue)
		Local fract:Float = hue - sextant
		Local vsf:Float = v * sv * fract
		Local mid1:Float = m + vsf
		Local mid2:Float = v - vsf
		
		Select sextant
			Case 0
				r = v
				g = mid1
				b = m

			Case 1
				r = mid2
				g = v
				b = m

			Case 2
				r = m
				g = v
				b = mid1

			Case 3
				r = m
				g = mid2
				b = v

			Case 4
				r = mid1
				g = m
				b = v
			
			Case 5
				r = v
				g = m
				b = mid2
		End
	End
		
	Return[Int(r * 255), Int(g * 255), Int(b * 255)]
End

'Adapted from https://www.cs.rit.edu/~ncs/color/t_convert.html
' h = [0,360], s = [0,1], v = [0,1]
'		if s = 0, then h = -1 (undefined)

Function RGBtoHSV:Float[] (r:Float, g:Float, b:Float)
	Local h:Float, s:Float, v:Float
	Local min:Float, max:Float, delta:Float

	r /= 255.0; g /= 255.0; b /= 255.0
	
	min = Min(Min(r, g), b)
	max = Max(Max(r, g), b)
	v = max				' v

	delta = max - min

	If max <> 0
		s = delta / max		' s
	Else 
		' r = g = b = 0		' s = 0, v is undefined
		s = 0
		h = -1
		Return[h, s, v]
	End If 

	If r = max 
		h = ( g - b ) / delta		' between yellow & magenta
	ElseIf g = max
		h = 2 + ( b - r ) / delta	' between cyan & yellow
	Else
		h = 4 + ( r - g ) / delta	' between magenta & cyan
	End If
		
		
	h *= 60				' degrees
	if h < 0 Then h += 360

	Return[h / 360.0, s, v]
End Function 

End Class