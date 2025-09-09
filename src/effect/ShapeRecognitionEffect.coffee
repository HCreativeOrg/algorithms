class ShapeRecognitionEffect extends Effect
    constructor: (@points) ->
        super()

    apply: (image) ->
        shapeRec = new window.ShapeRecognition()
        result = shapeRec.recognize(@points)
        if result
            bezierEffect = new window.BezierEffect(result.bezier, [255, 0, 0], 2)
            return bezierEffect.apply(image)
        else
            return image


window["ShapeRecognitionEffect"] = ShapeRecognitionEffect
