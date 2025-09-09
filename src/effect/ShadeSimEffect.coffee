class ShadeSimEffect extends Effect
    constructor: () ->
        super()
        @lightSource = {x: 0, y: -100}
        @width = 0
        @height = 0

    setDimensions: (@width, @height) ->

    drawPolygonOutline: (pixels, path, color, width) ->
        for i in [0...path.length]
            p1 = path[i]
            p2 = path[(i + 1) % path.length]
            @drawLine(pixels, p1, p2, color, 1, 1)
        return image

    applyShading: (path, shadingType, options = {}) ->
        return (image) =>
            @width = image.width
            @height = image.height
            newPixels = image.pixels.slice()
            switch shadingType
                when 'cross-hatch' then @crossHatchPixel(newPixels, path, options)
                when 'soft-shade' then @softShadePixel(newPixels, path, options)
                when 'cel-shade' then @celShadePixel(newPixels, path, options)
                else throw new Error("Unknown shading type: #{shadingType}")
            return {
                width: image.width
                height: image.height
                pixels: newPixels
            }

    crossHatchPixel: (pixels, path, options = {}) ->
        density = options.density || 5
        color = @hexToRgb(options.color || '#000000')
        opacity = options.opacity || 0.3
        useLightSource = options.useLightSource ? true

        bounds = @getPathBounds(path)
        if !bounds then return

        shapeCenter = {
            x: (bounds.minX + bounds.maxX) / 2
            y: (bounds.minY + bounds.maxY) / 2
        }

        if useLightSource
            [angle1, angle2] = @getCrossHatchAngles(shapeCenter)
        else
            angle1 = options.angle1 || 45
            angle2 = options.angle2 || -45

        @drawHatchLinesPixel(pixels, bounds, angle1, density, color, opacity)
        @drawHatchLinesPixel(pixels, bounds, angle2, density, color, opacity)

    softShadePixel: (pixels, path, options = {}) ->
        intensity = options.intensity || 0.5
        color = @hexToRgb(options.color || '#000000')
        useLightSource = options.useLightSource ? true

        bounds = @getPathBounds(path)
        if !bounds then return

        shapeCenter = {
            x: (bounds.minX + bounds.maxX) / 2
            y: (bounds.minY + bounds.maxY) / 2
        }

        if useLightSource
            lightAngle = @calculateLightAngle(shapeCenter)
            rad = lightAngle * Math.PI / 180

            gradientLength = Math.max(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY)
            startX = shapeCenter.x + Math.cos(rad) * gradientLength / 2
            startY = shapeCenter.y + Math.sin(rad) * gradientLength / 2
            endX = shapeCenter.x - Math.cos(rad) * gradientLength / 2
            endY = shapeCenter.y - Math.sin(rad) * gradientLength / 2

            @fillPolygonWithGradient(pixels, path, startX, startY, endX, endY, [0,0,0,0], color, intensity)
        else
            centerX = (bounds.minX + bounds.maxX) / 2
            centerY = (bounds.minY + bounds.maxY) / 2
            radius = Math.max(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY) / 2

            @fillPolygonWithRadialGradient(pixels, path, centerX, centerY, 0, centerX, centerY, radius, [0,0,0,0], color, intensity)

    celShadePixel: (pixels, path, options = {}) ->
        levels = options.levels || 3
        baseColor = @hexToRgb(options.baseColor || '#ffffff')
        shadowColor = @hexToRgb(options.shadowColor || '#cccccc')
        outlineColor = @hexToRgb(options.outlineColor || '#000000')
        outlineWidth = options.outlineWidth || 2
        useLightSource = options.useLightSource ? true

        bounds = @getPathBounds(path)
        if !bounds then return

        shapeCenter = {
            x: (bounds.minX + bounds.maxX) / 2
            y: (bounds.minY + bounds.maxY) / 2
        }

        if useLightSource
            lightAngle = @calculateLightAngle(shapeCenter)
            shadingIntensity = @calculateShadingIntensity(path, lightAngle)
        else
            shadingIntensity = 0.5

        for level in [0...levels]
            alpha = (level + 1) / levels * shadingIntensity * 0.4
            shadeColor = @interpolateColorRgb(baseColor, shadowColor, alpha)

            @fillPolygonSolid(pixels, path, shadeColor, alpha)

        @drawPolygonOutline(pixels, path, outlineColor, outlineWidth)

    fillPolygonSolid: (pixels, path, color, alpha = 1) ->
        bounds = @getPathBounds(path)
        for y in [Math.floor(bounds.minY)..Math.ceil(bounds.maxY)]
            intersections = []
            for i in [0...path.length]
                p1 = path[i]
                p2 = path[(i + 1) % path.length]
                if (p1.y <= y and p2.y > y) or (p1.y > y and p2.y <= y)
                    x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
                    intersections.push(x)
            intersections.sort((a, b) -> a - b)
            for i in [0...intersections.length] by 2
                if i + 1 < intersections.length
                    x1 = Math.ceil(intersections[i])
                    x2 = Math.floor(intersections[i + 1])
                    for x in [x1..x2]
                        @setPixel(pixels, x, y, color, alpha)

    fillPolygonWithGradient: (pixels, path, startX, startY, endX, endY, startColor, endColor, intensity) ->
        dx = endX - startX
        dy = endY - startY
        len = Math.sqrt(dx * dx + dy * dy)
        if len == 0
            @fillPolygonSolid(pixels, path, endColor, intensity)
            return
        bounds = @getPathBounds(path)
        for y in [Math.floor(bounds.minY)..Math.ceil(bounds.maxY)]
            intersections = []
            for i in [0...path.length]
                p1 = path[i]
                p2 = path[(i + 1) % path.length]
                if (p1.y <= y and p2.y > y) or (p1.y > y and p2.y <= y)
                    x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
                    intersections.push(x)
            intersections.sort((a, b) -> a - b)
            for i in [0...intersections.length] by 2
                if i + 1 < intersections.length
                    x1 = Math.ceil(intersections[i])
                    x2 = Math.floor(intersections[i + 1])
                    for x in [x1..x2]
                        px = x - startX
                        py = y - startY
                        dot = px * dx + py * dy
                        t = dot / (len * len)
                        t = Math.max(0, Math.min(1, t))
                        interpColor = @interpolateColorRgb(startColor, endColor, t)
                        interpAlpha = intensity * t
                        @setPixel(pixels, x, y, interpColor, interpAlpha)

    fillPolygonWithRadialGradient: (pixels, path, cx, cy, r1, cx2, cy2, r2, startColor, endColor, intensity) ->
        if r2 == 0
            @fillPolygonSolid(pixels, path, endColor, intensity)
            return
        bounds = @getPathBounds(path)
        for y in [Math.floor(bounds.minY)..Math.ceil(bounds.maxY)]
            intersections = []
            for i in [0...path.length]
                p1 = path[i]
                p2 = path[(i + 1) % path.length]
                if (p1.y <= y and p2.y > y) or (p1.y > y and p2.y <= y)
                    x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
                    intersections.push(x)
            intersections.sort((a, b) -> a - b)
            for i in [0...intersections.length] by 2
                if i + 1 < intersections.length
                    x1 = Math.ceil(intersections[i])
                    x2 = Math.floor(intersections[i + 1])
                    for x in [x1..x2]
                        dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
                        t = dist / r2
                        t = Math.min(1, t)
                        interpColor = @interpolateColorRgb(startColor, endColor, t)
                        interpAlpha = intensity * t
                        @setPixel(pixels, x, y, interpColor, interpAlpha)

    drawPolygonOutline: (pixels, path, color, width) ->
        for i in [0...path.length]
            p1 = path[i]
            p2 = path[(i + 1) % path.length]
            @drawLinePixel(pixels, p1.x, p1.y, p2.x, p2.y, color, width)

    drawHatchLinesPixel: (pixels, bounds, angle, density, color, opacity) ->
        rad = angle * Math.PI / 180
        cos = Math.cos(rad)
        sin = Math.sin(rad)
        spacing = Math.max(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY) / density

        for i in [-density...density*2]
            startX = bounds.minX + i * spacing * cos
            startY = bounds.minY + i * spacing * sin
            endX = startX + (bounds.maxX - bounds.minX) * cos
            endY = startY + (bounds.maxY - bounds.minY) * sin
            @drawLine(pixels, {x: startX, y: startY}, {x: endX, y: endY}, color, 1, opacity)

    getPathBounds: (path) ->
        if path.length == 0 then return null
        minX = Math.min(...path.map((p) -> p.x))
        maxX = Math.max(...path.map((p) -> p.x))
        minY = Math.min(...path.map((p) -> p.y))
        maxY = Math.max(...path.map((p) -> p.y))
        return {minX, maxX, minY, maxY}

    interpolateColorRgb: (c1, c2, factor) ->
        r = Math.round(c1[0] + (c2[0] - c1[0]) * factor)
        g = Math.round(c1[1] + (c2[1] - c1[1]) * factor)
        b = Math.round(c1[2] + (c2[2] - c1[2]) * factor)
        return [r, g, b]

    hexToRgb: (hex) ->
        result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
        if result
            return [
                parseInt(result[1], 16)
                parseInt(result[2], 16)
                parseInt(result[3], 16)
            ]
        return [0, 0, 0]

    setLightSource: (x, y) ->
        @lightSource = {x: x, y: y}

    getLightSource: () ->
        return @lightSource

    calculateLightAngle: (shapeCenter) ->
        dx = @lightSource.x - shapeCenter.x
        dy = @lightSource.y - shapeCenter.y
        return Math.atan2(dy, dx) * 180 / Math.PI

    calculateShadowAngle: (shapeCenter) ->
        lightAngle = @calculateLightAngle(shapeCenter)
        return lightAngle + 180

    getCrossHatchAngles: (shapeCenter) ->
        shadowAngle = @calculateShadowAngle(shapeCenter)
        perpendicularAngle = shadowAngle + 90
        return [shadowAngle, perpendicularAngle]

    calculateShadingIntensity: (path, lightAngle) ->
        if path.length < 3 then return 0.5
        pathAngle = @calculatePathDirection(path)
        
        angleDiff = Math.abs(lightAngle - pathAngle)
        angleDiff = Math.min(angleDiff, 360 - angleDiff)

        intensity = Math.abs(Math.sin(angleDiff * Math.PI / 180))

        return Math.max(0.1, Math.min(1.0, intensity))

    calculatePathDirection: (path) ->
        if path.length < 2 then return 0
        start = path[0]
        end = path[path.length - 1]
        dx = end.x - start.x
        dy = end.y - start.y
        return Math.atan2(dy, dx) * 180 / Math.PI

window["ShadeSimEffect"] = ShadeSimEffect
