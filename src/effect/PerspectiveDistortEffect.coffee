class PerspectiveDistortEffect extends Effect
    constructor: (@bezier) ->
        super()

    apply: (image) ->
        
        distort = new window.PerspectiveDistort()
        return distort.distort(image, @bezier)


window["PerspectiveDistortEffect"] = PerspectiveDistortEffect
