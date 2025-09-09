class BrushStrokeEffect extends Effect
    constructor: (@brushStroke, @color = [0, 0, 0], @width = 1) ->
        super()

    apply: (image) ->
        @width = image.width
        @height = image.height
        newPixels = image.pixels.slice()

        points = @brushStroke.getPoints()

        for i in [1...points.length]
            @drawLine(newPixels, points[i-1], points[i], @color, @width, 1)

        return {
            width: image.width
            height: image.height
            pixels: newPixels
        }

window["BrushStrokeEffect"] = BrushStrokeEffect
