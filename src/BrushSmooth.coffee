
class HCBrushStabilization
    constructor() ->
        @smoothingFactor = 0.5
        @mostDeviantPoints = []
        @deviations = []
    
    beginDraw() ->
        return
            newPoint: (x, y) =>
                point = {x, y}
                if @lastPoint?
                    dx = x - @lastPoint.x
                    dy = y - @lastPoint.y
                    smoothedX = @lastPoint.x + dx * @smoothingFactor
                    smoothedY = @lastPoint.y + dy * @smoothingFactor
                    smoothedPoint = {x: smoothedX, y: smoothedY}
                else
                    smoothedPoint = point
                @lastPoint = smoothedPoint
                deviation = Math.sqrt((point.x - smoothedPoint.x) ** 2 + (point.y - smoothedPoint.y) ** 2)
                @deviations.push(deviation)
                if @deviations.length > 10
                    @deviations.shift()
                averageDeviation = @deviations.reduce(((a, b) -> a + b), 0) / @deviations.length
                if averageDeviation > 5
                    @smoothingFactor = Math.min(0.9, @smoothingFactor + 0.05)
                else if averageDeviation < 2
                    @smoothingFactor = Math.max(0.1, @smoothingFactor - 0.05)
                @mostDeviantPoints.push({original: point, smoothed: smoothedPoint, deviation: deviation})
                return smoothedPoint
            endDraw: () =>
                @mostDeviantPoints = []
                @lastPoint = null
                @deviations = []


window["BrushStabilization"] = HCBrushStabilization