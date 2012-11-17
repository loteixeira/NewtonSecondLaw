package br.dcoder.simulation1d
{
	import br.dcoder.VectorUtil;
	import br.dcoder.console.Console;

	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.bit101.components.Window;
	import com.bit101.components.InputText;

	import flash.display.Shape;	
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	/**
	 * @author Lucas Teixeira
	 */
	public class Simulation1D extends Sprite
	{
		private static const METER_SCALE:uint = 100;
		private static const BODY_LENGTH:uint = 50;
		private static const GRAVITY:Number = 9.80665;
		
		private static const CHART_WIDTH:uint = 240;
		private static const CHART_HEIGHT:uint = 240;
		
		private var simulation:Sprite;
		private var body:Shape;
		private var vectors:Shape;
		private var ruler:Shape;
		
		private var frictionCoefficient:Number;
		private var mass:Number;
		private var position:Number;
		private var velocity:Number;
		
		private var forceStart:Number;
		private var forceEnd:Number;
		
		private var working:Boolean;
		private var running:Boolean;
		private var lastUpdate:uint;
		private var totalTime:Number;
		
		private var menu:Window;
		private var clearButton:PushButton;
		private var runButton:PushButton;
		private var massInput:InputText;
		private var frictionInput:InputText;
		private var forceLabel:Label;
		
		private var chart:Window;
		private var chartData:Shape;
		
		public function Simulation1D()
		{
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			
			stage.addEventListener(Event.ENTER_FRAME, enterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			
			Console.TRACE_ECHO = true;
			Console.create(stage);
			Console.getInstance().area = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			Console.getInstance().hide();
			cpln("Starting Simulation 1D");
			
			forceStart = 0;
			forceEnd = 0;
			working = false;
			running = false;
			lastUpdate = 0;
			totalTime = 0;
			
			start();
		}
		
		private function start():void
		{
			simulation = new Sprite();
			simulation.x = Math.round(stage.stageWidth / 2);
			simulation.y = Math.round(stage.stageHeight / 1.3);
			addChild(simulation);
			
			body = new Shape();
			simulation.addChild(body);
			
			vectors = new Shape();
			simulation.addChild(vectors);
			
			ruler = new Shape();
			simulation.addChild(ruler); 

			resetBody();
			
			drawBody();
			drawRuler();
			
			createUI();
		}
		
		private function resetBody():void
		{
			totalTime = 0;
			
			mass = 15;
			position = 0;
			velocity = 0;
			
			forceStart = 0;
			forceEnd = 0;
			
			body.x = 0;
		}
		
		private function drawBody():void
		{
			body.graphics.clear();
			body.graphics.beginFill(0xcccccc);
			body.graphics.drawRect(position, position, BODY_LENGTH, BODY_LENGTH);
			body.graphics.endFill();
		}
		
		private function drawRuler():void
		{
			ruler.graphics.clear();
			
			ruler.graphics.lineStyle(1, 0x000000);
			ruler.graphics.moveTo(-stage.stageWidth / 2, 50);
			ruler.graphics.lineTo(stage.stageWidth / 2, 50);
			
			for (var i:int = -stage.stageWidth / 2; i < stage.stageWidth; i += 10)
			{
				if (i % METER_SCALE == 0)
				{
					ruler.graphics.lineStyle(2, 0x000000);
					ruler.graphics.moveTo(i, 50);
					ruler.graphics.lineTo(i, 40);
				}
				else
				{
					ruler.graphics.lineStyle(1, 0x000000);
					ruler.graphics.moveTo(i, 50);
					ruler.graphics.lineTo(i, 45);
				}
			}
		}
		
		private function createUI():void
		{
			menu = new Window(this, stage.stageWidth - 200, 50, "Control");
			menu.height = 160;
			menu.width = 150;
			
			clearButton = new PushButton(menu, 10, 20, "Clean", clearClick);
			clearButton.width = 60;
			runButton = new PushButton(menu, 80, 20, "Run", runClick);
			runButton.width = 60;
			
			new Label(menu, 15, 50, "Mass (kg):");
			massInput = new InputText(menu, 80, 50, "15", function(e:Event):void
			{
				mass = parseFloat(massInput.text);
			
				if (isNaN(mass))
				{
					mass = 15;
					massInput.text = "15";
				}				
			});
			massInput.restrict = "0123456789.,";
			massInput.width = 60;
			
			new Label(menu, 15, 72, "Coefficient\nof friction:");
			frictionInput = new InputText(menu, 80, 80, "0.0", function(e:Event):void
			{
				frictionCoefficient = parseFloat(frictionInput.text);
			
				if (isNaN(frictionCoefficient))
				{
					frictionCoefficient = 0;
					frictionInput.text = "0.0";
				}
			});
			frictionInput.restrict = "0123456789.,";
			frictionInput.width = 60;
			
			forceLabel = new Label(menu, 15, 105, "Force: 0");
			
			// chart
			chart = new Window(this, 50, 50, "Chart");
			chart.height = 310;
			chart.width = 330;
			
			var i:Number;
			var minX:Number = 30;
			var minY:Number = 30;
			var maxX:Number = minX + CHART_WIDTH;
			var maxY:Number = minY + CHART_WIDTH;

			// x axis
			var xAxis:Shape = new Shape();
			xAxis.graphics.lineStyle(1, 0x000000);
			xAxis.graphics.moveTo(minX, maxY);
			xAxis.graphics.lineTo(maxX, maxY);
			
			for (i = minX; i <= maxX; i += (maxX - minX) / 10)
			{
				xAxis.graphics.moveTo(i, maxY);
				xAxis.graphics.lineTo(i, maxY - 5);				
			}
			
			// y axis
			chart.content.addChild(xAxis);
			
			var yAxis:Shape = new Shape();
			yAxis.graphics.lineStyle(1, 0x000000);
			yAxis.graphics.moveTo(minX, minY);
			yAxis.graphics.lineTo(minX, maxY);
			
			for (i = minY; i < maxY; i += (maxY - minY) / 10)
			{
				yAxis.graphics.moveTo(minX, i);
				yAxis.graphics.lineTo(minX + 5, i);				
			}
			
			chart.content.addChild(yAxis);
			
			// chart data
			chartData = new Shape();
			chartData.x = minX;
			chartData.y = maxY;
			chartData.graphics.moveTo(0, -CHART_HEIGHT / 2);
			chart.content.addChild(chartData);
			
			// chart mask
			var chartMask:Shape = new Shape();
			chartMask.graphics.beginFill(0xff0000);
			chartMask.graphics.drawRect(minX, minY, maxX - minX, maxY - minY);
			chart.content.addChild(chartMask);
			chartData.mask = chartMask;
			
			// x axis label
			new Label(chart, 10, 5, "position (m)");
			// y axis label
			new Label(chart, minX + CHART_WIDTH + 5, minY + CHART_HEIGHT - 15, "time (s)");
		}
		
		private function clearChart():void
		{
			chartData.graphics.clear();
			chartData.graphics.moveTo(0, -CHART_HEIGHT / 2);
		}

		private function enterFrame(e:Event):void
		{
			vectors.graphics.clear();
			
			if (running)
			{
				var now:uint = getTimer();
				var interval:Number = (now - lastUpdate) / 1000;
				lastUpdate = now;
				
				totalTime += interval;
			
				var velocityDec:Number = (velocity > 0 ? -1 : 1) * frictionCoefficient * mass * GRAVITY * interval;
				
				if (Math.abs(velocityDec) < Math.abs(velocity))
				{
					velocity += velocityDec;
				}
				else
				{
					velocity = 0;
					forceStart = 0;
					forceEnd = 0;
					running = false;
				}
			
				position += velocity;
				body.x = position;
			
				var globalBody:Point = simulation.localToGlobal(new Point(body.x, body.y));
			
				if (globalBody.x + BODY_LENGTH < 0 || globalBody.x > stage.stageWidth)
				{
					forceLabel.text = "Force: 0";
					clearChart();
					resetBody();
					running = false;
				}
				
				if (running)
				{
					var chartX:Number = totalTime * (CHART_WIDTH / 4);
					var chartY:Number = -((position + stage.stageWidth / 2) / stage.stageWidth) * CHART_HEIGHT;
				
					chartData.graphics.lineStyle(1, 0xff0000);
					chartData.graphics.lineTo(chartX, chartY);
				}
			}
			else if (forceStart != 0 || forceEnd != 0) 
			{
				var l:Number;
				var translation:Point;
					
				// force vector;
				l = forceEnd - forceStart;
				translation = new Point(body.x + BODY_LENGTH / 2, BODY_LENGTH / 2);

				translation.x += forceStart > forceEnd ? -BODY_LENGTH / 2 : BODY_LENGTH / 2;
				translation.x += l;

				VectorUtil.draw(vectors.graphics, new Point(forceStart - forceEnd, 0), translation);
					
				// friction vector
				if (frictionCoefficient > 0)
				{
					var frictionVec:Point = new Point(-frictionCoefficient * mass * GRAVITY * (forceStart > forceEnd ? 1 : -1), 0);

					l = frictionVec.length;				
					translation = new Point(body.x + BODY_LENGTH / 2, BODY_LENGTH / 2);
					translation.x += forceStart > forceEnd ? BODY_LENGTH / 2 : -BODY_LENGTH / 2;
					translation.x += forceStart > forceEnd ? l : -l;
				
					VectorUtil.draw(vectors.graphics, frictionVec, translation);
				}
			}
			
			if (forceStart != 0 || forceEnd != 0)
			{
				forceLabel.text = "Force: " + (Math.round((forceStart - forceEnd) * 10) / 10) + " N";
			}
			
			runButton.enabled = !running && (forceStart != 0 || forceEnd != 0);
			massInput.enabled = !running;
			frictionInput.enabled = !running;
		}
		
		private function mouseDown(e:MouseEvent):void
		{
			if (velocity == 0)
			{
				var mouse:Point = simulation.globalToLocal(new Point(e.stageX, e.stageY));
			
				if (mouse.x >= body.x && mouse.x <= body.x + BODY_LENGTH)
				{
					if (mouse.y >= body.y && mouse.y <= body.y + BODY_LENGTH)
					{
						working = true;
						forceStart = mouse.x;
						forceEnd = forceStart;
						stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
					}
				}
			}
		}
		
		private function mouseMove(e:MouseEvent):void
		{
			var mouse:Point = simulation.globalToLocal(new Point(e.stageX, e.stageY));
			forceEnd = mouse.x;
		}
		
		private function mouseUp(e:MouseEvent):void
		{
			if (working)
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			
				var mouse:Point = simulation.globalToLocal(new Point(e.stageX, e.stageY));
				forceEnd = mouse.x;
				working = false;
			}
		}
		
		private function applyForce(force:Number):void
		{
			velocity += force / mass;
		}
		
		private function clearClick(e:MouseEvent):void
		{
			forceLabel.text = "Force: 0";
			clearChart();
			resetBody();
			running = false;
		}
		
		private function runClick(e:MouseEvent):void
		{
			running = true;
			lastUpdate = getTimer();
			mass = parseFloat(massInput.text);
			
			if (isNaN(mass))
			{
				mass = 15;
				massInput.text = "15";
			}
			
			frictionCoefficient = parseFloat(frictionInput.text);
			
			if (isNaN(frictionCoefficient))
			{
				frictionCoefficient = 0;
				frictionInput.text = "0.0";
			}
			
			applyForce(forceStart - forceEnd);
		}
	}
}
