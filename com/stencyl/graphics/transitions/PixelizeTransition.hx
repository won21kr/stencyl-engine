package com.stencyl.graphics.transitions;

import nme.geom.Rectangle;
import nme.display.Sprite;
import nme.display.Graphics;
import nme.display.BitmapData;
import nme.display.Shape;

import com.stencyl.Engine;

import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Linear;

class PixelizeTransition extends Transition
{
	//needs to be public so that it can be tweened
	public var pixelSize:Int;
		
	private var beginPixelSize:Int;
	private var endPixelSize:Int;
	
	private var rect:Shape;
	private var graphics:Graphics;
	private var srcImg:BitmapData;
	
	private var c:Int;
	private var r:Int;
			
	private var xOverflow:Int;
	private var yOverflow:Int;
			
	private var pixelRect:Rectangle;
	private var halfSize:Int;
	
	public function new(duration:Float, beginPixelSize:Int, endPixelSize:Int) 
	{
		super(duration);
			
		this.beginPixelSize = beginPixelSize;
		this.endPixelSize = endPixelSize;
		pixelSize = beginPixelSize;
	}
	
	override public function start()
	{
		active = true;
		
		rect = new Shape();
		graphics = rect.graphics;
		srcImg = new BitmapData(Engine.screenWidth, Engine.screenHeight);
		pixelRect = new Rectangle(0, 0, 0, 0);		
		
		Engine.engine.transitionLayer.addChild(rect);
		
		Actuate.tween(this, duration, { pixelSize:endPixelSize } ).ease(Linear.easeNone).onComplete(stop);
	}
	
	override public function draw(g:Graphics)
	{
		if(pixelSize == 1)
		{
			return;
		}
		
		graphics.clear();
		srcImg.draw(Engine.engine.master);
		
		c = Math.ceil(Engine.screenWidth / pixelSize);
		r = Math.ceil(Engine.screenHeight / pixelSize);
			
		xOverflow = Std.int(c * pixelSize - Engine.screenWidth);
		yOverflow = Std.int(r * pixelSize - Engine.screenHeight);
			
		pixelRect.x = -xOverflow / 2;
		pixelRect.y = -yOverflow / 2;
		pixelRect.height = pixelRect.width = pixelSize;
		
		halfSize = Std.int(pixelSize / 2);
			
		for(i in 0...r)
		{
			for(j in 0...c)
			{
				graphics.beginFill(srcImg.getPixel32(Std.int(pixelRect.x + halfSize), Std.int(pixelRect.y + halfSize)));
				graphics.drawRect(pixelRect.x, pixelRect.y, pixelRect.width, pixelRect.height);
				graphics.endFill();
				
				pixelRect.x += pixelSize;
			}
			
			pixelRect.x = -xOverflow / 2;
			pixelRect.y += pixelSize;
		}		
	}
	
	override public function cleanup()
	{		
		if(rect != null)
		{
			Engine.engine.transitionLayer.removeChild(rect);
			rect = null;
		}
	}
	
}