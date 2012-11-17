package br.dcoder
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	/**
	 * @author Lucas Teixeira
	 */
	public class VectorUtil
	{
		private static const zero:Point = new Point(0, 0);
		
		public static function draw(g:Graphics, vector:Point, translation:Point = null, dashed:Boolean = false):void
		{
			if (!translation)
			{
				translation = zero;
			}
			
			g.lineStyle(2, 0x000000);
			
			var angle:Number = Math.atan2(vector.x, vector.y);
			
			if (angle == 0)
			{
				angle = -Math.PI / 2;
			}

			g.beginFill(0x000000);			
			g.moveTo(translation.x + vector.x, translation.y + vector.y);
			g.lineTo(translation.x + vector.x - 3 * Math.sin(angle + Math.PI / 6), translation.y + vector.y - 3 * Math.cos(angle + Math.PI / 6));
			g.lineTo(translation.x + vector.x - 3 * Math.sin(angle - Math.PI / 6), translation.y + vector.y - 3 * Math.cos(angle - Math.PI / 6));
			g.endFill();
			
			if (dashed)
			{
				var l:Number = vector.length - 5;
				var unit:Point = new Point(vector.x, vector.y);
				unit.normalize(1);
				
				for (var i:uint = 0; i < l; i += 10)
				{
					g.moveTo(translation.x + unit.x * i, translation.y + unit.y * i);
					g.lineTo(translation.x + unit.x * (i + 5), translation.y + unit.y * (i + 5));
				}
			}
			else
			{
				g.moveTo(translation.x, translation.y);
				g.lineTo(translation.x + vector.x, translation.y + vector.y);
			}
		}
	}
}
