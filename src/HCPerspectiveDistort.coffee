class HCPerspectiveDistort
    ###
    Distort an image to fit a bezier shape using perspective transform.
    @param {Object} image - {width, height, pixels} where pixels is array of [r,g,b]
    @param {HCBezier} bezier - The bezier path defining the target shape
    ###
    distort: (image, bezier) ->
        targetCorners = [
            bezier.renderAtProgress(0.0)
            bezier.renderAtProgress(0.25)
            bezier.renderAtProgress(0.5)
            bezier.renderAtProgress(0.75)
        ]
        
        srcCorners = [
            {x: 0, y: 0}
            {x: image.width - 1, y: 0}
            {x: image.width - 1, y: image.height - 1}
            {x: 0, y: image.height - 1}
        ]
        
        minX = Math.min(...targetCorners.map(p => p.x))
        maxX = Math.max(...targetCorners.map(p => p.x))
        minY = Math.min(...targetCorners.map(p => p.y))
        maxY = Math.max(...targetCorners.map(p => p.y))
        
        outputWidth = Math.ceil(maxX - minX)
        outputHeight = Math.ceil(maxY - minY)
        
        translatedTarget = targetCorners.map(p => ({x: p.x - minX, y: p.y - minY}))
        
        H = @computeHomography(srcCorners, translatedTarget)
        
        invH = @matrixInverse3x3(H)
        
        outputPixels = new Array(outputWidth * outputHeight * 3)
        
        for y in [0...outputHeight]
            for x in [0...outputWidth]
                srcPos = @applyHomography(invH, {x: x, y: y})
                
                color = @sampleBilinear(image, srcPos.x, srcPos.y)
                
                idx = (y * outputWidth + x) * 3
                outputPixels[idx] = color[0]
                outputPixels[idx + 1] = color[1]
                outputPixels[idx + 2] = color[2]
        
        return {
            width: outputWidth
            height: outputHeight
            pixels: outputPixels
        }
    
    computeHomography: (src, dst) ->
        A = []
        b = []
        
        for i in [0...4]
            x = src[i].x
            y = src[i].y
            xp = dst[i].x
            yp = dst[i].y
            
            A.push([x, y, 1, 0, 0, 0, -x * xp, -y * xp])
            A.push([0, 0, 0, x, y, 1, -x * yp, -y * yp])
            
            b.push(xp)
            b.push(yp)
        
        h = @solveLinearSystem(A, b)
        
        return [
            [h[0], h[1], h[2]]
            [h[3], h[4], h[5]]
            [h[6], h[7], 1]
        ]
    
    solveLinearSystem: (A, b) ->
        n = 8
        augmented = A.map((row, i) => row.concat([b[i]]))
        
        for i in [0...n]
            maxRow = i
            for k in [i+1...n]
                if Math.abs(augmented[k][i]) > Math.abs(augmented[maxRow][i])
                    maxRow = k

            [augmented[i], augmented[maxRow]] = [augmented[maxRow], augmented[i]]
            
            for k in [i+1...n]
                c = -augmented[k][i] / augmented[i][i]
                for j in [i...n+1]
                    if i == j
                        augmented[k][j] = 0
                    else
                        augmented[k][j] += c * augmented[i][j]
        
        x = new Array(n)
        for i in [n-1..0]
            x[i] = augmented[i][n]
            for j in [i+1...n]
                x[i] -= augmented[i][j] * x[j]
            x[i] /= augmented[i][i]
        
        return x
    
    matrixInverse3x3: (M) ->
        det = M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) -
              M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0]) +
              M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0])
        
        if Math.abs(det) < 1e-10
            throw new Error("Matrix is singular")
        
        invDet = 1 / det
        
        return [
            [
                (M[1][1] * M[2][2] - M[1][2] * M[2][1]) * invDet,
                (M[0][2] * M[2][1] - M[0][1] * M[2][2]) * invDet,
                (M[0][1] * M[1][2] - M[0][2] * M[1][1]) * invDet
            ],
            [
                (M[1][2] * M[2][0] - M[1][0] * M[2][2]) * invDet,
                (M[0][0] * M[2][2] - M[0][2] * M[2][0]) * invDet,
                (M[0][2] * M[1][0] - M[0][0] * M[1][2]) * invDet
            ],
            [
                (M[1][0] * M[2][1] - M[1][1] * M[2][0]) * invDet,
                (M[0][1] * M[2][0] - M[0][0] * M[2][1]) * invDet,
                (M[0][0] * M[1][1] - M[0][1] * M[1][0]) * invDet
            ]
        ]
    
    applyHomography: (H, p) ->
        x = p.x
        y = p.y
        w = H[2][0] * x + H[2][1] * y + H[2][2]
        xp = (H[0][0] * x + H[0][1] * y + H[0][2]) / w
        yp = (H[1][0] * x + H[1][1] * y + H[1][2]) / w
        return {x: xp, y: yp}
    
    sampleBilinear: (image, x, y) ->
        x0 = Math.floor(x)
        y0 = Math.floor(y)
        x1 = x0 + 1
        y1 = y0 + 1
        
        x0 = Math.max(0, Math.min(x0, image.width - 1))
        x1 = Math.max(0, Math.min(x1, image.width - 1))
        y0 = Math.max(0, Math.min(y0, image.height - 1))
        y1 = Math.max(0, Math.min(y1, image.height - 1))
        
        wx = x - x0
        wy = y - y0
        
        idx00 = (y0 * image.width + x0) * 3
        idx10 = (y0 * image.width + x1) * 3
        idx01 = (y1 * image.width + x0) * 3
        idx11 = (y1 * image.width + x1) * 3
        
        c00 = [image.pixels[idx00], image.pixels[idx00+1], image.pixels[idx00+2]]
        c10 = [image.pixels[idx10], image.pixels[idx10+1], image.pixels[idx10+2]]
        c01 = [image.pixels[idx01], image.pixels[idx01+1], image.pixels[idx01+2]]
        c11 = [image.pixels[idx11], image.pixels[idx11+1], image.pixels[idx11+2]]
        
        r = (1 - wx) * (1 - wy) * c00[0] + wx * (1 - wy) * c10[0] + (1 - wx) * wy * c01[0] + wx * wy * c11[0]
        g = (1 - wx) * (1 - wy) * c00[1] + wx * (1 - wy) * c10[1] + (1 - wx) * wy * c01[1] + wx * wy * c11[1]
        b = (1 - wx) * (1 - wy) * c00[2] + wx * (1 - wy) * c10[2] + (1 - wx) * wy * c01[2] + wx * wy * c11[2]
        
        return [Math.round(r), Math.round(g), Math.round(b)]


window["PerspectiveDistort"] = HCPerspectiveDistort