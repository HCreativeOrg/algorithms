class FloodFillEffect extends Effect
    constructor: (@startPoint, @fillColor, @tolerance = 10) ->
        super()

    apply: (image) ->
        
        data = []
        for y in [0...image.height]
            row = []
            for x in [0...image.width]
                idx = (y * image.width + x) * 3
                row.push([image.pixels[idx], image.pixels[idx+1], image.pixels[idx+2]])
            data.push(row)

        floodFill = new window.FloodFill(image.width, image.height, data)
        floodFill.fill(@startPoint.x, @startPoint.y, @fillColor, [], @tolerance)

        newPixels = []
        for y in [0...image.height]
            for x in [0...image.width]
                color = data[y][x]
                newPixels.push(color[0], color[1], color[2])

        return {
            width: image.width
            height: image.height
            pixels: newPixels
        }


window["FloodFillEffect"] = FloodFillEffect
