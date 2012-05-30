package com.stencyl.models;

import com.stencyl.models.Actor;
import com.stencyl.models.collision.Hitbox;
import com.stencyl.utils.Utils;

import box2D.collision.B2AABB;
import box2D.common.math.B2Transform;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.B2FixtureDef;
import box2D.collision.shapes.B2Shape;
import box2D.collision.shapes.B2CircleShape;
import box2D.collision.shapes.B2PolygonShape;

import nme.geom.Rectangle;

class Region extends Actor
{
	public var isCircle:Bool;
	
	///All Hash sets of Integers
	private var containedActors:IntHash<Int>;

	private var copy:B2Shape;
	
	//Strictly used in non-Box2D mode
	public var simpleBounds:Rectangle;
	
	public var regionWidth:Float;
	public var regionHeight:Float;
	
	private var originalWidth:Float;
	private var originalHeight:Float;
			
	public var whenActorEntersListeners:Array<Dynamic>;
	public var whenActorExitsListeners:Array<Dynamic>;
	
	private var justAdded:Array<Dynamic>;
	private var justRemoved:Array<Dynamic>;

	public function new(game:Engine, x:Float, y:Float, shapes:Array<B2Shape>, simpleBounds:Rectangle = null)
	{
		super(game, 0, -2, x, y, game.getTopLayer(), Engine.NO_PHYSICS ? simpleBounds.width : 1, Engine.NO_PHYSICS ? simpleBounds.height : 1, 
		      null, null, null, null, 
		      false, false, false, false, 
		      Engine.NO_PHYSICS ? null : shapes[0],
		      0, Engine.NO_PHYSICS
		      );
	
		alwaysSimulate = true;
		isRegion = true;
		isTerrainRegion = false;
		solid = true;
		
		this.simpleBounds = simpleBounds;
		copy = shapes[0];
		
		containedActors = new IntHash<Int>();
		whenActorEntersListeners = new Array<Dynamic>();
		whenActorExitsListeners = new Array<Dynamic>();
		
		justAdded = new Array<Dynamic>();
		justRemoved = new Array<Dynamic>();
		
		if(!Engine.NO_PHYSICS)
		{
			body.setSleepingAllowed(true);
			body.setAwake(false);
			body.setIgnoreGravity(true);
		}
		
		var lowerXBound:Float = 0;
		var upperXBound:Float = 0;
		var lowerYBound:Float = 0;
		var upperYBound:Float = 0;
		
		if(Engine.NO_PHYSICS)
		{
			upperXBound = simpleBounds.width;
			upperYBound = simpleBounds.height;
					
			originalWidth = regionWidth = Math.round(Engine.toPixelUnits(Math.abs(lowerXBound - upperXBound)));
			originalHeight = regionHeight = Math.round(Engine.toPixelUnits(Math.abs(lowerYBound - upperYBound)));
		}
		
		else
		{
			if(Std.is(shapes[0], B2PolygonShape))
			{
				isCircle = false;
				var trans = new B2Transform();
				trans.setIdentity();
				
				var aabb = new B2AABB();
				
				cast(shapes[0], B2PolygonShape).computeAABB(aabb, trans);
				
				lowerXBound = aabb.lowerBound.x;
				upperXBound = aabb.upperBound.x;
				lowerYBound = aabb.lowerBound.y;
				upperYBound = aabb.upperBound.y;
				
				for(i in 0...shapes.length)
				{
					var fixture = new B2FixtureDef();
					fixture.isSensor = true;
					fixture.userData = this;
					fixture.shape = shapes[i];
					fixture.friction = 1.0;
					fixture.density = 0.1;
					fixture.restitution = 0;
					fixture.groupID = -1000;
	
					body.createFixture(fixture);
					
					cast(shapes[i], B2PolygonShape).computeAABB(aabb, trans);
					lowerXBound = Math.min(lowerXBound, aabb.lowerBound.x);
					upperXBound = Math.max(upperXBound, aabb.upperBound.x);
					lowerYBound = Math.min(lowerYBound, aabb.lowerBound.y);
					upperYBound = Math.max(upperYBound, aabb.upperBound.y);
				}
				
				originalWidth = regionWidth = Math.round(Engine.toPixelUnits(Math.abs(lowerXBound - upperXBound)));
				originalHeight = regionHeight = Math.round(Engine.toPixelUnits(Math.abs(lowerYBound - upperYBound)));
			}
				
			else if(Std.is(shapes[0], B2CircleShape))
			{
				isCircle = true;
				
				originalWidth = regionWidth = Engine.toPixelUnits(cast(shape, B2CircleShape).m_radius * 2);
				originalHeight = regionHeight = Engine.toPixelUnits(cast(shape, B2CircleShape).m_radius * 2);
			}
		}
	}
	
	public function containsActor(actor:Actor):Bool
	{
		if(actor != null)
		{
			return containedActors.exists(actor.ID);
		}
		
		else
		{
			return false;
		}
	}
	
	public function getContainedActors():IntHash<Int>
	{
		return containedActors;
	}
	
	public function addActor(actor:Actor)
	{
		if(actor == null)
		{
			return;	
		}
		
		if(actor.ID != -1 && !containedActors.exists(actor.ID))
		{
			containedActors.set(actor.ID, actor.ID);
			
			var index = Utils.indexOf(justRemoved, actor);
			
			if(index == -1)
			{
				justAdded.push(actor);					
			}
			
			else 
			{
				justRemoved.splice(index, 1);
			}
		}
	}
	
	public function removeActor(actor:Actor)
	{
		if(actor == null)
		{
			return;	
		}
		
		if(actor.ID != -1)
		{
			containedActors.remove(actor.ID);
			justRemoved.push(actor);				
		}
	}
	
	override public function follow(actor:Actor)
	{
		var x = actor.getX() + actor.getWidth() / 2;
		var y = actor.getY() + actor.getHeight() / 2;
		
		setX(x);
		setY(y);
		
		//technically we should clear containedActors...
	}
	
	public function resetSize()
	{
		setRegionSize(originalWidth, originalHeight);
	}
	
	public function setRegionDiameter(diameter:Float)
	{
		setRegionSize(diameter, diameter);
	}
	
	public function setRegionSize(width:Float, height:Float)
	{
		var oldWidth:Float = regionWidth;
		var oldHeight:Float = regionHeight;
		
		width = Engine.toPhysicalUnits(width);
		height = Engine.toPhysicalUnits(height);
		
		var shape:B2Shape;
		
		if(isCircle)
		{
			var s = new B2CircleShape();
			s.m_radius = width / 2;
			shape = s;
		}
			
		else
		{
			var s2 = new B2PolygonShape();
			s2.setAsBox(width/2, height/2);
			shape = s2;
		}
		
		var fixture = new B2FixtureDef();
		fixture.isSensor = true;
		fixture.userData = this;
		fixture.shape = shape;
		
		if(body != null && body.getFixtureList() != null)
		{
			while(body.m_fixtureCount > 0)
			{
				body.DestroyFixture(body.getFixtureList());
			}
			
			body.createFixture(fixture);
			
			regionWidth = Engine.toPixelUnits(width);
			regionHeight = Engine.toPixelUnits(height);
		}
		
		var dw = (regionWidth - oldWidth);
		var dh = (regionHeight - oldHeight);
		
		//Back up
		setLocation(getX() + (dw)/2, getY() + (dh)/2);
	}
	
	override public function setLocation(x:Float, y:Float)
	{
		setX(x + regionWidth / 2);
		setY(y + regionHeight / 2);
	}
	
	override public function getWidth():Float
	{
		return regionWidth;
	}
	
	override public function getHeight():Float
	{
		return regionHeight;
	}
	
	override public function isMouseOver():Bool
	{
		//This may need to be in global x/y???
		var mx:Int = Input.mouseX;
		var my:Int = Input.mouseY;
		
		var xPos:Float = getX() - regionWidth/2;
		var yPos:Float = getY() - regionHeight/2;

		return (mx >= xPos && 
		   		my >= yPos && 
		   		mx < xPos + regionWidth && 
		   		my < yPos + regionHeight);
	}
	
	override public function innerUpdate(elapsedTime:Float, hudCheck:Bool)
	{					
		while(justAdded.length > 0)
		{				
			var a = cast(justAdded.pop(), Actor);
			Engine.invokeListeners2(whenActorEntersListeners, a);
		}
		
		while(justRemoved.length > 0)
		{
			var a = cast(justRemoved.pop(), Actor);
			Engine.invokeListeners2(whenActorExitsListeners, a);
		}
		
		if(mouseOverListeners.length > 0)
		{
			checkMouseState();
		}
	}
}