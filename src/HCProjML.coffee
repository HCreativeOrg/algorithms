###
ACProjML

name:"project" revision:1
data:[
objKey1=>objValue1
objKey2=>objValue2
]
prev:[[
objKey1=>oldValue1
objKey2=>oldValue2
] [
objKey1=>olderValue1
objKey2=>olderValue2
]]
###

class ACProjMLEncoder
    constructor: (meta, obj, prev) ->
        @name = meta.name
        @revision = meta.revision
        @data = obj
        @prev = prev

    buildValue: (value, indent = "") ->
        if typeof value is "object" and value isnt null
            if Array.isArray(value)
                str = "[\n"
                for item in value
                    str += "#{indent}  #{ @buildValue(item, indent + "  ") }\n"
                str += "#{indent}]"
            else
                str = "{\n"
                for key, val of value
                    str += "#{indent}  #{key}:#{ @buildValue(val, indent + "  ") }\n"
                str += "#{indent}}"
        else
            if typeof value is "string"
                if /[{}[\]:\"\n\\]/.test(value)
                    escaped = value.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')
                    str = "\"#{escaped}\""
                else
                    str = value
            else
                str = "#{value}"
        return str

    build: () ->
        str = "name:\"#{@name}\" revision:#{@revision}\n"
        if @prev.length > 0
            diffObj = @diff()
            str += "data:[\n"
            for key, value of diffObj
                str += "#{key}:#{ @buildValue(value) }\n"
            str += "]\n"
        else
            str += "data:[\n"
            for key, value of @data
                str += "#{key}:#{ @buildValue(value) }\n"
            str += "]\n"
        str += "prev:[\n"
        for item in @prev
            str += "[\n"
            for key, value of item
                str += "#{key}:#{ @buildValue(value) }\n"
            str += "]\n"
        str += "]\n"
        return str

    diff: () ->
        if @prev.length is 0
            return { added: @data, removed: {}, changed: {} }
        prevData = @prev[@prev.length - 1]
        added = {}
        removed = {}
        changed = {}
        for key, value of @data
            if not prevData[key]?
                added[key] = value
            else if JSON.stringify(value) isnt JSON.stringify(prevData[key])
                changed[key] = { from: prevData[key], to: value }
        for key, value of prevData
            if not @data[key]?
                removed[key] = value
        return { added, removed, changed }

class ACProjMLDecoder
    constructor: (str) ->
        @str = str

    parsePrimitive: (str) ->
        if str.startsWith('"')
            return str.slice(1, -1).replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\')
        else if str == "true"
            return true
        else if str == "false"
            return false
        else if str == "null"
            return null
        else if /^\d+$/.test(str)
            return parseInt(str)
        else if /^\d+\.\d+$/.test(str)
            return parseFloat(str)
        else
            return str

    parseValue: (lines, index) ->
        line = lines[index].trim()
        if line.startsWith("{")
            obj = {}
            index++
            while index < lines.length and not lines[index].trim().endsWith("}")
                if lines[index].trim() isnt ""
                    [key, ...rest] = lines[index].split(":")
                    key = key.trim()
                    valueStr = rest.join(":").trim()
                    if valueStr.startsWith("{") or valueStr.startsWith("[")
                        [parsedValue, index] = @parseValue(lines, index)
                        obj[key] = parsedValue
                    else
                        obj[key] = @parsePrimitive(valueStr)
                index++
            return [obj, index + 1]
        else if line.startsWith("[")
            arr = []
            index++
            while index < lines.length and not lines[index].trim().endsWith("]")
                if lines[index].trim() isnt ""
                    if lines[index].trim().startsWith("{") or lines[index].trim().startsWith("[")
                        [parsedValue, index] = @parseValue(lines, index)
                        arr.push(parsedValue)
                    else
                        arr.push(@parsePrimitive(lines[index].trim()))
                index++
            return [arr, index + 1]
        else
            return [@parsePrimitive(line), index + 1]

    applyDiff: (base, diff) ->
        result = Object.assign({}, base)
        for key, value of diff.added
            result[key] = value
        for key, value of diff.removed
            delete result[key]
        for key, change of diff.changed
            result[key] = change.to
        return result

    parseBlock: (lines) ->
        obj = {}
        index = 0
        while index < lines.length
            line = lines[index]
            if line.trim() isnt ""
                [key, ...rest] = line.split(":")
                key = key.trim()
                valueStr = rest.join(":").trim()
                if valueStr.startsWith("{") or valueStr.startsWith("[")
                    [parsedValue, index] = @parseValue(lines, index)
                    obj[key] = parsedValue
                else
                    obj[key] = @parsePrimitive(valueStr)
                    index++
            else
                index++
        return obj

    parse: () ->
        lines = @str.split("\n")
        metaLine = lines[0]
        metaParts = metaLine.split(" ")
        namePart = metaParts[0]
        revisionPart = metaParts[1]
        name = namePart.split(":")[1].replace(/"/g, "")
        revision = parseInt(revisionPart.split(":")[1])
        dataStartIndex = lines.indexOf("data:[") + 1
        dataEndIndex = lines.indexOf("]", dataStartIndex)
        dataLines = lines.slice(dataStartIndex, dataEndIndex)
        data = @parseBlock(dataLines)
        prevStartIndex = lines.indexOf("prev:[", dataEndIndex) + 1
        prevEndIndex = lines.indexOf("]", prevStartIndex)
        prevLines = lines.slice(prevStartIndex, prevEndIndex)
        prev = []
        currentBlock = []
        for line in prevLines
            if line.trim() == "["
                currentBlock = []
            else if line.trim() == "]"
                if currentBlock.length > 0
                    prev.push(@parseBlock(currentBlock))
            else
                currentBlock.push(line)
        if prev.length > 0
            data = @applyDiff(prev[prev.length - 1], data)
        return {
            name: name,
            revision: revision,
            data: data,
            prev: prev
        }

###
Usage:

meta = { name: "project", revision: 1 }
obj = { key1: "value1", key2: 42, key3: { subkey: "subvalue" }, key4: [1, 2, 3] }
prev = [
    { key1: "oldValue1", key2: 41, key3: { subkey: "oldSubvalue" }, key4: [1, 2] }
    { key1: "olderValue1", key2: 40, key3: { subkey: "olderSubvalue" }, key4: [1] }
]

encoder = new ACProjMLEncoder(meta, obj, prev)
str = encoder.build()
console.log(str)

decoder = new ACProjMLDecoder(str)
parsed = decoder.parse()
console.log(parsed)
###

window["ProjML"] = { ACProjMLEncoder, ACProjMLDecoder }