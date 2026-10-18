package funkin.backend.system.framerate;

import flixel.FlxState;

import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;

import openfl.display.Shape;
import openfl.display.Sprite;

import openfl.geom.Rectangle;

import openfl.text.TextField;
import openfl.text.TextFormat;

enum DebugType
{
	// hides everything
	HIDDEN;

	// only shows fps counter
	BASIC;

	// shows fps and memory counter
	NORMAL;

	// shows graph alongside fps and memory counter
	ADVANCED;
}

class Framerate extends Sprite
{
    public var lerpSpeed:Float = 0.5;

    public static var instance:Framerate;
    public static var isLoaded:Bool = false;

    public static var textFormat:TextFormat;
    public static var smallTextFormat:TextFormat;

    public static var debugMode:DebugType = Options.fpsCounter ? BASIC : HIDDEN;
    public static var showDebugInfo:Bool = false;

    public static var offset:FlxPoint = new FlxPoint();

    public var counters:Sprite;
    public var graphs:Sprite;
    public var debugCounters:Sprite;

    public var boxOutline:Shape;
    public var box:Shape;

    public var debugBoxOutline:Shape;
    public var debugBox:Shape;
    public var debugSeparators:Shape;

    public var fpsCounter:TextField;
    public var memoryCounter:TextField;

    public var debugTitles:Array<TextField> = [];
    public var debugInfos:Array<TextField> = [];

    public var fpsGraph:Shape;
    public var memoryGraph:Shape;
	
    public var currentFPS:Int = 0;

    public var memory:Float = 0;
    public var memoryPeak:Float = 0;

    private var times:Array<Float> = [];
    private var currentTime:Float = 0;
    private var cacheCount:Int = 0;

    private var fpsHistory:Array<Float> = [];
    private var memoryHistory:Array<Float> = [];
    private var updateTimer:Float = 100;

    private var fpsBounds:Rectangle = new Rectangle();
    private var memoryBounds:Rectangle = new Rectangle();

    private var boxBounds:Rectangle = new Rectangle();
    private var boxTarget:Rectangle = new Rectangle();
    private var snapBox:Bool = true;

    private var debugBoxBounds:Rectangle = new Rectangle();
    private var debugBoxTarget:Rectangle = new Rectangle();
    private var snapDebugBox:Bool = true;

    public function new()
    {
        super();

        if (instance != null)
            return;

        instance = this;
        isLoaded = true;

        debugCounters = new Sprite();
        debugCounters.alpha = 0;
        addChild(debugCounters);

        counters = new Sprite();
        counters.alpha = 0;
        addChild(counters);

        debugBoxOutline = createBox(debugCounters);
        debugBox = createBox(debugCounters);

        debugSeparators = new Shape();
        debugCounters.addChild(debugSeparators);

        for (title in ["State", "Conductor", "Flixel"])
        {
            var titleText:TextField = createText(debugCounters, 0.9);

            titleText.text = title;

            debugTitles.push(titleText);
            debugInfos.push(createText(debugCounters, 0.7));
        }

        boxOutline = createBox(counters);
        box = createBox(counters);

        fpsCounter = createText(counters, 0.9);
        memoryCounter = createText(counters, 0);

        fpsCounter.y = 17;

        graphs = new Sprite();
        graphs.alpha = 0;
        counters.addChild(graphs);

        fpsGraph = new Shape();
        graphs.addChild(fpsGraph);

        memoryGraph = new Shape();
        graphs.addChild(memoryGraph);

        boxBounds.setTo(fpsCounter.x + 3, fpsCounter.y + 2, 0, 0);
        positionBoxes(boxOutline, box, boxBounds);

        reload();
    }

    public function reload():Void
    {
        textFormat = new TextFormat(Paths.getFontName(Paths.font("perep.ttf")), 15, -1);
        smallTextFormat = new TextFormat(Paths.getFontName(Paths.font("perep.ttf")), 12, -1);

        fpsCounter.defaultTextFormat = textFormat;
        memoryCounter.defaultTextFormat = smallTextFormat;

        for (title in debugTitles)
            title.defaultTextFormat = textFormat;

        for (info in debugInfos)
            info.defaultTextFormat = smallTextFormat;

        updateTimer = 100;
        snapDebugBox = true;
    }

    private function createBox(parent:Sprite):Shape
    {
        var shape:Shape = new Shape();

        shape.graphics.beginFill(0x000000);
        shape.graphics.drawRect(0, 0, 1, 1);
        shape.graphics.endFill();

        shape.alpha = 0.3;

        parent.addChild(shape);

        return shape;
    }

    private function createText(parent:Sprite, alpha:Float):TextField
    {
        var text:TextField = new TextField();

        text.autoSize = LEFT;

        text.x = 16;

        text.alpha = alpha;

        text.selectable = false;
        text.mouseEnabled = false;

        parent.addChild(text);

        return text;
    }

    private function positionBoxes(outline:Shape, inner:Shape, bounds:Rectangle):Void
    {
        outline.x = bounds.x - 10;
        outline.y = bounds.y - 10;

        outline.width = bounds.width + 20;
        outline.height = bounds.height + 20;

        inner.x = bounds.x - 5;
        inner.y = bounds.y - 5;

        inner.width = bounds.width + 10;
        inner.height = bounds.height + 10;
    }

    private function lerpBounds(bounds:Rectangle, target:Rectangle):Void
    {
        bounds.x = CoolUtil.fpsLerp(bounds.x, target.x, lerpSpeed);
        bounds.y = CoolUtil.fpsLerp(bounds.y, target.y, lerpSpeed);

        bounds.width = CoolUtil.fpsLerp(bounds.width, target.width, lerpSpeed);
        bounds.height = CoolUtil.fpsLerp(bounds.height, target.height, lerpSpeed);
    }

    private function getTextBounds(text:TextField):Rectangle
    {
        var size:Float = text.defaultTextFormat.size;
        var side:Float = size * 0.05;

        return new Rectangle(text.x + 3 + side, text.y + 2, text.textWidth - side * 2, text.textHeight - size * 0.18);
    }

    private function placeText(text:TextField, y:Float):Rectangle
    {
        var bounds:Rectangle = getTextBounds(text);

        text.y += y - bounds.y;
        bounds.y = y;

        return bounds;
    }

    public override function __enterFrame(t:Float):Void
    {
        super.__enterFrame(t);

        currentTime += t;
        times.push(currentTime);

        while (times[0] < currentTime - 1000)
            times.shift();

        var currentCount:Int = times.length;

        currentFPS = Math.round((currentCount + cacheCount) / 2);
        cacheCount = currentCount;

        memory = MemoryUtil.currentMemUsage();

        if (memoryPeak < memory)
            memoryPeak = memory;

        updateTimer += t;

        if (updateTimer >= 100)
        {
            updateTimer = 0;

            updateStats();

            if (debugCounters.visible)
                updateDebugInfo();
        }

        if (debugMode == HIDDEN)
            snapBox = true;

        if (!showDebugInfo)
            snapDebugBox = true;

        x = offset.x * FlxG.scaleMode.scale.x;
        y = offset.y * FlxG.scaleMode.scale.y;

        counters.alpha = CoolUtil.fpsLerp(counters.alpha, debugMode != HIDDEN ? 1 : 0, lerpSpeed);
        memoryCounter.alpha = CoolUtil.fpsLerp(memoryCounter.alpha, debugMode == NORMAL || debugMode == ADVANCED ? 0.7 : 0, lerpSpeed);
        graphs.alpha = CoolUtil.fpsLerp(graphs.alpha, debugMode == ADVANCED ? 1 : 0, lerpSpeed);
        debugCounters.alpha = CoolUtil.fpsLerp(debugCounters.alpha, showDebugInfo ? 1 : 0, lerpSpeed);

        counters.visible = counters.alpha > 0.01;
        memoryCounter.visible = memoryCounter.alpha > 0.01;
        graphs.visible = graphs.alpha > 0.01;
        debugCounters.visible = debugCounters.alpha > 0.01;

        if (counters.visible)
            updateCounters();

        if (debugCounters.visible)
            updateDebugBox();
    }

    private function updateStats():Void
    {
        fpsCounter.text = Std.string(currentFPS);
        memoryCounter.text = '${CoolUtil.getSizeString(memory)} - ${CoolUtil.getSizeString(memoryPeak)}';
        memoryCounter.y = fpsCounter.y + fpsCounter.textHeight;

        fpsBounds = getTextBounds(fpsCounter);
        memoryBounds = getTextBounds(memoryCounter);

        record(fpsHistory, currentFPS);
        record(memoryHistory, memory);

        if (debugMode == ADVANCED)
            drawGraphs();
    }

    private function updateCounters():Void
    {
        if (debugMode != HIDDEN)
        {
            boxTarget = fpsBounds;

            if (debugMode == NORMAL || debugMode == ADVANCED)
                boxTarget = boxTarget.union(memoryBounds);

            if (debugMode == ADVANCED)
                boxTarget = boxTarget.union(new Rectangle(memoryBounds.x, memoryBounds.bottom + 4, memoryBounds.width, 24));
        }

        if (debugMode != HIDDEN && snapBox)
        {
            boxBounds.copyFrom(boxTarget);
            snapBox = false;
        }
        else
            lerpBounds(boxBounds, boxTarget);

        positionBoxes(boxOutline, box, boxBounds);
    }

    private function updateDebugBox():Void
    {
        var targetY:Float = debugMode != HIDDEN ? boxOutline.y + boxOutline.height + 6 : boxOutline.y;

        if (showDebugInfo && snapDebugBox)
        {
            updateDebugInfo();

            debugBoxBounds.copyFrom(debugBoxTarget);
            debugCounters.y = targetY;
			
            snapDebugBox = false;
        }
        else
        {
            lerpBounds(debugBoxBounds, debugBoxTarget);
            debugCounters.y = CoolUtil.fpsLerp(debugCounters.y, targetY, lerpSpeed);
        }

        positionBoxes(debugBoxOutline, debugBox, debugBoxBounds);
    }

    private function updateDebugInfo():Void
    {
        var info:Array<String> = [getStateInfo(), getConductorInfo(), getFlixelInfo()];
        var separators:Array<Float> = [];
        var bounds:Rectangle = new Rectangle();
		
        var y:Float = 10;
        for (i in 0...debugTitles.length)
        {
            if (i > 0)
            {
                separators.push(y + 6);
                y += 6 * 2 + 1;
            }

            debugInfos[i].text = info[i];

            var title:Rectangle = placeText(debugTitles[i], y);
            var content:Rectangle = placeText(debugInfos[i], title.bottom + 4);

            bounds = bounds.union(title).union(content);
            y = content.bottom;
        }

        debugSeparators.graphics.clear();
        debugSeparators.graphics.beginFill(0xFFFFFF, 0.3);

        for (separator in separators)
            debugSeparators.graphics.drawRect(bounds.x, separator, bounds.width, 1);

        debugSeparators.graphics.endFill();

        debugBoxTarget = bounds;
    }

    private function getStateInfo():String
    {
        var subState:String = FlxG.state.subState != null ? getStateName(FlxG.state.subState) : "None";
        return 'Current: ${getStateName(FlxG.state)}\nSubstate: ${subState}';
    }

    private function getStateName(state:FlxState):String
    {
        if (state is ModState)
            return cast (state, ModState).scriptName;

        if (state is ModSubState)
            return cast (state, ModSubState).scriptName;

        return Type.getClassName(Type.getClass(state));
    }

    private function getConductorInfo():String
    {
        var conductor:Conductor = Conductor.instance;
        return 'Position: ${Math.floor(conductor.songPosition)}ms\nBPM: ${conductor.bpm} (${conductor.beatsPerMeasure}/${conductor.stepsPerBeat})\nStep: ${conductor.curStep}\nBeat: ${conductor.curBeat}\nMeasure: ${conductor.curMeasure}';
    }

    private function getFlixelInfo():String
    {
        var bitmaps:Int = @:privateAccess Lambda.count(FlxG.bitmap._cache);
        return 'Total Objects: ${FlxG.state.members.length}\nCamera Count: ${FlxG.cameras.list.length}\nCached Bitmaps: ${bitmaps}\nCached Sounds: ${FlxG.sound.list.length}\nFlxGame Child Count: ${FlxG.game.numChildren}';
    }

    private function record(history:Array<Float>, value:Float):Void
    {
        history.push(value);

        if (history.length > 40)
            history.shift();
    }

    private function drawGraphs():Void
    {
        var graphWidth:Float = Math.floor((memoryBounds.width - 4) / 2);

        graphs.x = memoryBounds.x;
        graphs.y = memoryBounds.bottom + 4;
        memoryGraph.x = memoryBounds.width - graphWidth;

        drawGraph(fpsGraph, fpsHistory, graphWidth);
        drawGraph(memoryGraph, memoryHistory, graphWidth);
    }

    private function drawGraph(graph:Shape, history:Array<Float>, width:Float):Void
    {
        var peak:Float = 1;

        for (value in history)
            peak = Math.max(peak, value);

        graph.graphics.clear();

        graph.graphics.beginFill(0x000000, 0.3);
        graph.graphics.drawRect(0, 0, width, 24);
        graph.graphics.endFill();

        graph.graphics.lineStyle(1, 0xFFFFFF, 0.5);
        graph.graphics.moveTo(0, 0);
        graph.graphics.lineTo(0, 24);
        graph.graphics.lineTo(width, 24);

        graph.graphics.lineStyle(1, 0xFFFFFF, 0.8);

        for (i in 0...history.length)
        {
            var x:Float = 1 + i * ((width - 2) / (39));
            var y:Float = 24 - 1 - history[i] / peak * (24 - 2);

            if (i == 0)
                graph.graphics.moveTo(x, y);
            else
                graph.graphics.lineTo(x, y);
        }
    }
}