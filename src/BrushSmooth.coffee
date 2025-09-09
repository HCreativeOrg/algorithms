class HCBrushStroke
    constructor: (mode = 'brush') ->
        @mode = mode
        @smoothingFactor = if @mode == 'brush' then 0.65 else 1.0
        @adaptive = @mode == 'brush'
        @mostDeviantPoints = []
        @deviations = []

    setMode: (mode) ->
        @mode = mode
        @smoothingFactor = if @mode == 'brush' then 0.65 else 1.0
        @adaptive = @mode == 'brush'

    beginDraw: ->
        @lastPoint = null
        @deviations = []
        @mostDeviantPoints = []
        return {
            newPoint: (x, y) =>
                point = {x, y}
                if @lastPoint?
                    dx = x - @lastPoint.x
                    dy = y - @lastPoint.y
                    if @mode == 'brush'
                        smoothedX = @lastPoint.x + dx * @smoothingFactor
                        smoothedY = @lastPoint.y + dy * @smoothingFactor
                    else
                        smoothedX = x
                        smoothedY = y
                    smoothedPoint = {x: smoothedX, y: smoothedY}
                else
                    smoothedPoint = point
                @lastPoint = smoothedPoint
                deviation = Math.sqrt((point.x - smoothedPoint.x) ** 2 + (point.y - smoothedPoint.y) ** 2)
                @deviations.push(deviation)
                if @adaptive
                    if @deviations.length > 10
                        @deviations.shift()
                    averageDeviation = @deviations.reduce(((a, b) -> a + b), 0) / @deviations.length
                    if averageDeviation > 5
                        @smoothingFactor = Math.min(0.9, @smoothingFactor + 0.05)
                    else if averageDeviation < 2
                        @smoothingFactor = Math.max(0.1, @smoothingFactor - 0.05)
                @mostDeviantPoints.push({original: point, smoothed: smoothedPoint, deviation: deviation})
            getPoints: () ->
                return @mostDeviantPoints.map (p) -> p.smoothed
        }


window["BrushStroke"] = HCBrushStroke