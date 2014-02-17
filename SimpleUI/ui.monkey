Import mojo
Import brl.json

'Summary:  Generic namespace for various SimpleUI functions.
Class UI Final
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
	
	'Summary:  Generates a unique ID for widgets.
	Function GenerateID:Int(salt:Int)
		'To generate a unique ID, we must find a number that's unlikely to be repeated no matter how many widgets we add here.
		'Doing this in int32 space is difficult, so we comprimise by attempting to fill most of the values in the upper limit
		'of this space.  14 bits of data (not counting the sign bit) are allocated high and assigned to a random number, then
		'masked against the current stack size.  This should provide unique values for at least 100,000 widgets, while giving
		'only a 1-in-16382 chance of an auto ID collision if the stack size shrinks and stack length is repeated again.

		'All negative numbers (except for -1), and numbers from 0-$1FFFF are all valid ID's that can be manually assigned
		'with no chance of a collision by the auto-assignment.
				
		Return (Rnd(1, $3FFF) Shl 17) | salt 'Auto-assign a unique widget ID. Should support >100k widgets.
	End Function
End Class

