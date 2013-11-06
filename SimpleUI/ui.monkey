Import mojo

'Summary:  Generic namespace for various SimpleUI functions.
Class UI
	'Summary:  Returns True if (px, py) are within rect (x,y,w,h).
	Function WithinRect:Bool(px:Float, py:Float, x:Float, y:Float, w:Float, h:Float)
		If px >= x And px <= x+w And py >= y And py < y+h Then	Return true Else Return False
	End Function
	
	'Summary:  Sets a scissor which respects the current matrix's scale and translation values.
	Function SetXformedScissor:Void(x:Float, y:Float, w:Float, h:Float)
		Local matrix:Float[] = GetMatrix()
		SetScissor(x * matrix[0] + matrix[4], y * matrix[3] + matrix[5], w * matrix[0], h * matrix[3])
	End Function
	
	Global scissorStack:= New Float[4 * 32], scissorSp
	'Summary: Saves the current Scissor to the stack for later restoration.
	Function PushScissor:Void()
		Local sp:Int = scissorSp
		Local m:Float[] = GetScissor()
		scissorStack[sp + 0] = m[0]
		scissorStack[sp + 1] = m[1]
		scissorStack[sp + 2] = m[2]
		scissorStack[sp + 3] = m[3]
		scissorSp = sp + 4
	End Function
	'Summary:  Saves an arbitrary Scissor to the stack for later restoration.
	Function PushScissor:Void(scissor:Float[])
		Local sp:Int = scissorSp
		Local m:Float[] = scissor
		scissorStack[sp + 0] = m[0]
		scissorStack[sp + 1] = m[1]
		scissorStack[sp + 2] = m[2]
		scissorStack[sp + 3] = m[3]
		scissorSp = sp + 4
	End Function
	
	'Summary:  Restores the last saved scissor from the stack.
	Function PopScissor:Void()
		Local sp = scissorSp - 4
		SetScissor(scissorStack[sp + 0], scissorStack[sp + 1], scissorStack[sp + 2], scissorStack[sp + 3])
		scissorSp = sp
	End Function
	
	Function GetLastPushedScissor:Float[] (logToDebug:Bool = False)
		Local out:Float[4]
		Local sp = scissorSp - 4
		out[0] = scissorStack[sp + 0]
		out[1] = scissorStack[sp + 1]
		out[2] = scissorStack[sp + 2]
		out[3] = scissorStack[sp + 3]
		
		If logToDebug Then DebugLog("(" + out[0] + "," + out[1] + "," + out[2] + "," + out[3] + ") Stack position " + int(sp / 4))
		Return out
	End Function
	
	'Summary:  Returns the distance between two points, squared
	Function DistSq:Float(x:Float, y:Float, x2:Float, y2:Float) 
		Return (x2 - x) * (x2 - x) + (y2 - y) * (y2 - y)
	End Function
	
	'Summary:  Returns a value between startValue and endValue by precentage 0-1.
	Function Lerp:Float(startValue:Float, endValue:Float, percent:Float)
		Return startValue + (endValue - startValue) * percent
	End
	
End Class