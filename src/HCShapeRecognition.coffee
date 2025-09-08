class HCShapeRecognition
    constructor: ->
        @pathSimplify = new window.PathSimplify(8)

    recognize: (points) ->
        if not points or points.length < 2
            return null

        @pathSimplify.points = points.slice()
        simplified = @pathSimplify.simplify()

        if simplified.length < 2
            return null

        closed = @distance(simplified[0], simplified[simplified.length - 1]) < 20

        bezierPoints = simplified.map (p) -> {x: p.x, y: p.y, _type: 'linear'}

        if simplified.length == 2
            type = 'line'
        else if simplified.length == 3
            type = 'triangle'
        else if simplified.length == 4 and @isRectangle(simplified)
            type = 'rectangle'
        else if closed
            type = 'closed_shape'
        else
            type = 'curve'

        bezier = new window.Bezier(bezierPoints, closed)

        return {
            type: type,
            bezier: bezier,
            points: simplified
        }

    isRectangle: (points) ->
        if points.length != 4
            return false

        d1 = @distance(points[0], points[1])
        d2 = @distance(points[1], points[2])
        d3 = @distance(points[2], points[3])
        d4 = @distance(points[3], points[0])

        sides = [d1, d2, d3, d4]
        avg = sides.reduce((a, b) -> a + b) / 4
        maxDiff = Math.max(...sides.map((d) -> Math.abs(d - avg)))

        if maxDiff > avg * 0.4
            return false

        for i in [0..3]
            p0 = points[i]
            p1 = points[(i + 1) % 4]
            p2 = points[(i + 2) % 4]

            v1 = {x: p1.x - p0.x, y: p1.y - p0.y}
            v2 = {x: p2.x - p1.x, y: p2.y - p1.y}

            dot = v1.x * v2.x + v1.y * v2.y
            len1 = Math.sqrt(v1.x ** 2 + v1.y ** 2)
            len2 = Math.sqrt(v2.x ** 2 + v2.y ** 2)

            if len1 == 0 or len2 == 0
                return false

            cos = dot / (len1 * len2)
            cos = Math.max(-1, Math.min(1, cos))
            angle = Math.acos(cos) * 180 / Math.PI

            if Math.abs(angle - 90) > 30
                return false

        return true

    distance: (p1, p2) ->
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        return Math.sqrt(dx ** 2 + dy ** 2)


window["ShapeRecognition"] = HCShapeRecognition