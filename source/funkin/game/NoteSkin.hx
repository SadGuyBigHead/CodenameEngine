package funkin.game;

import haxe.Json;
import haxe.io.Path;

final class NoteSkin
{
	public static final DEFAULT_ID:String = 'game/notes/default';

	static var cache:Map<String, NoteSkin> = [];

	@:optional
	@:jcustomparse(dave.data.DataParse.scalePoint)
	@:jcustomwrite(dave.data.DataWrite.scalePoint)
	public var scale:FlxPoint;

	@:optional
	public var covers:NoteSkinHoldCovers;

	@:optional
	public var arrows:NoteSkinArrows;

	@:optional
	public var receptors:NoteSkinReceptors;

	@:jignored
	public var id:String;

	// stupid whatever
	public static function get(path:String)
	{
		final id:String = Path.withoutExtension(path);
		if (cache.exists(id))
			return cache[id];

		final jsonPath = Paths.getPath(Path.normalize("images/" + Path.withExtension(path, "json")));
		final isDefault:Bool = id == DEFAULT_ID;
		final def:NoteSkin = cache[DEFAULT_ID];

		final parser = new json2object.JsonParser<NoteSkin>();
		final noteSkin:NoteSkin = parser.fromJson(Assets.getText(jsonPath)) ?? new NoteSkin();
		
		for (error in parser.errors)
			trace('NoteSkin Error ($id): ' + json2object.ErrorUtils.convertError(error));

		if (!isDefault)
		{
			noteSkin.merge(def);
		}
		noteSkin.id = id;

		return cache[id] = noteSkin;
	}

	public function merge(other:NoteSkin)
	{
		this.scale ??= other.scale.clone();
		this.covers = other.covers.clone(this.covers);
		this.arrows = other.arrows.clone(this.arrows);
		this.receptors = other.receptors.clone(this.receptors);
	}

	function new()
	{
	}
}

final class NoteSkinHoldCovers
{
	@:default("game/notes/cover")
	public var asset:String;

	@:jcustomparse(dave.data.DataParse.scalePoint)
	@:jcustomwrite(dave.data.DataWrite.scalePoint)
	public var scale:FlxPoint;

	@:jcustomparse(dave.data.DataParse.point)
	@:jcustomwrite(dave.data.DataWrite.point)
	public var offset:FlxPoint;

	@:optional
	public var anims:Array<NoteSkinHoldCoverAnimations>;

	public function new()
	{
	}

	public function merge(other:NoteSkinHoldCovers)
	{
		this.scale ??= other.scale.clone();
		this.offset ??= other.offset.clone();
		this.anims ??= [];
		for (i in 0...this.anims.length)
			this.anims[i] = other.anims[i].clone(this.anims[i]);
	}

	public function clone(covers:NoteSkinHoldCovers):NoteSkinHoldCovers
	{
		covers ??= new NoteSkinHoldCovers();
		covers.merge(this);
		return covers;
	}
}

final class NoteSkinHoldCoverAnimations
{
	public var start:NoteSkinAnimation;
	public var hold:NoteSkinAnimation;
	public var end:NoteSkinAnimation;

	public function new()
	{
	}

	public function merge(other:NoteSkinHoldCoverAnimations)
	{
		this.start = other.start.clone(this.start);
		this.hold = other.hold.clone(this.hold);
		this.end = other.end.clone(this.end);
	}

	public function clone(anims:NoteSkinHoldCoverAnimations)
	{
		anims ??= new NoteSkinHoldCoverAnimations();
		this.merge(anims);
		return anims;
	}
}

final class NoteSkinArrows
{
	@:optional
	public var anims:Array<NoteSkinArrowAnimations>;

	public function new()
	{
	}

	public function merge(other:NoteSkinArrows)
	{
		this.anims ??= [];
		for (i in 0...other.anims.length)
			this.anims[i] = other.anims[i].clone(this.anims[i]);
	}

	public function clone(arrows:NoteSkinArrows)
	{
		arrows ??= new NoteSkinArrows();
		arrows.merge(this);
		return arrows;
	}
}

final class NoteSkinArrowAnimations
{
	public var scroll:NoteSkinAnimation;
	public var holdBody:NoteSkinAnimation;
	public var holdCap:NoteSkinAnimation;

	public function new()
	{
	}

	public function merge(other:NoteSkinArrowAnimations)
	{
		this.scroll = other.scroll.clone(this.scroll);
		this.holdBody = other.holdBody.clone(this.holdBody);
		this.holdCap = other.holdCap.clone(this.holdCap);
	}

	public function clone(anims:NoteSkinArrowAnimations)
	{
		anims ??= new NoteSkinArrowAnimations();
		anims.merge(this);
		return anims;
	}
}

final class NoteSkinReceptors
{
	public var anims:Array<NoteSkinReceptor>;

	public function new()
	{
	}

	public function merge(other:NoteSkinReceptors)
	{
		this.anims ??= [];
		for (i in 0...other.anims.length)
			this.anims[i] = other.anims[i].clone(this.anims[i]);
	}

	public function clone(receptors:NoteSkinReceptors)
	{
		receptors ??= new NoteSkinReceptors();
		receptors.merge(this);
		return receptors;
	}
}

// what do i call this
final class NoteSkinReceptor
{
	public var normal:NoteSkinReceptorAnimations;
	public var shape:NoteSkinReceptorAnimations;
	public var transition:NoteSkinAnimation;

	public function new()
	{
	}

	public function merge(other:NoteSkinReceptor)
	{
		this.normal = other.normal.clone(this.normal);
		this.shape = other.shape.clone(this.shape);
		this.transition = other.transition.clone(this.transition);
	}

	public function clone(receptor:NoteSkinReceptor)
	{
		receptor ??= new NoteSkinReceptor();
		receptor.merge(this);
		return receptor;
	}
}

final class NoteSkinReceptorAnimations
{
	// bruh
	@:alias("static")
	public var staticAnim:NoteSkinAnimation;
	public var pressed:NoteSkinAnimation;
	public var confirm:NoteSkinAnimation;

	public function new()
	{

	}

	public function merge(other:NoteSkinReceptorAnimations)
	{
		this.staticAnim = other.staticAnim.clone(this.staticAnim);
		this.pressed = other.pressed.clone(this.pressed);
		this.confirm = other.confirm.clone(this.confirm);
	}

	public function clone(anims:NoteSkinReceptorAnimations)
	{
		anims ??= new NoteSkinReceptorAnimations();
		anims.merge(this);
		return anims;
	}
}

final class NoteSkinAnimation
{
	public var name:String;

	@:optional
	public var fps:Null<Float>;

	public function new()
	{
	}

	public function merge(other:NoteSkinAnimation)
	{
		this.name ??= other.name;
		this.fps ??= other.fps;
	}

	public function clone(anim:NoteSkinAnimation)
	{
		anim ??= new NoteSkinAnimation();
		anim.merge(this);
		return anim;
	}
}
