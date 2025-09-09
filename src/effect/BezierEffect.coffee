class BezierEffect extends Effect
    constructor: (@bezier, @color = [0, 0, 0], @width = 1) ->
        super()

    apply: (image) ->
        @width = image.width
        @height = image.height
        newPixels = image.pixels.slice()

        steps = Math.max(100, image.width + image.height)
        points = []
        for i in [0..steps]
            t = i / steps
            point = @bezier.renderAtProgress(t)
            points.push(point)

        for i in [1...points.length]
            @drawLine(newPixels, points[i-1], points[i], @color, @width, 1)

        return {
            width: image.width
            height: image.height
            pixels: newPixels
        }

window["BezierEffect"] = BezierEffect
