class Effect
    ###
    Abstract base class for image effects.
    Subclasses should implement the apply method.
    @param {Object} image - {width, height, pixels: [r,g,b,...]}
    @return {Object} modified image
    ###
    apply: (image) ->
        throw new Error("Subclasses must implement apply method")

    drawLine: (pixels, p1, p2, color, lineWidth, alpha = 1) ->
        x1 = Math.round(p1.x)
        y1 = Math.round(p1.y)
        x2 = Math.round(p2.x)
        y2 = Math.round(p2.y)

        dx = Math.abs(x2 - x1)
        dy = Math.abs(y2 - y1)
        sx = if x1 < x2 then 1 else -1
        sy = if y1 < y2 then 1 else -1
        err = dx - dy

        while true
            @setPixel(pixels, x1, y1, color, alpha)
            if x1 == x2 and y1 == y2
                break
            e2 = 2 * err
            if e2 > -dy
                err -= dy
                x1 += sx
            if e2 < dx
                err += dx
                y1 += sy

    setPixel: (pixels, x, y, color, alpha = 1) ->
        if x >= 0 and x < @width and y >= 0 and y < @height
            idx = (y * @width + x) * 3
            pixels[idx] = Math.round(pixels[idx] * (1 - alpha) + color[0] * alpha)
            pixels[idx + 1] = Math.round(pixels[idx + 1] * (1 - alpha) + color[1] * alpha)
            pixels[idx + 2] = Math.round(pixels[idx + 2] * (1 - alpha) + color[2] * alpha)

window["Effect"] = Effect
