function renderFigletText(textString, fontFile)
    persistent fontCache;
    
    if isempty(fontCache)
        fontCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    if isKey(fontCache, fontFile)
        figletFont = fontCache(fontFile);
    else
        fontFile = downloadIfURL(fontFile);
        figletFont = loadFigletFont(fontFile);
        fontCache(fontFile) = figletFont;
    end
    
    printFiglet(textString, figletFont);
end

function localFile = downloadIfURL(filePath)
    if startsWith(filePath, 'http')
        [scriptPath, ~, ~] = fileparts(mfilename('fullpath'));
        [~, name, ext] = fileparts(filePath);
        localFile = fullfile(scriptPath, [name, ext]);
        websave(localFile, filePath);
    else
        localFile = filePath;
    end
end

function figletFont = loadFigletFont(fontFile)
    fid = fopen(fontFile, 'r');
    if fid < 0
        error('Could not open file: %s', fontFile);
    end

    headerLine = fgetl(fid);
    if ~startsWith(headerLine, 'flf2a')
        fclose(fid);
        error('Not a valid FIGlet .flf file.');
    end

    parts = strsplit(headerLine, ' ');
    hardblank = parts{1}(end);
    height = str2double(parts{2});
    commentCount = str2double(parts{6});

    for c = 1:commentCount
        fgetl(fid);
    end

    glyphMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
    spaceGlyph = repmat({' '}, 1, height);
    
    for asciiCode = 32:126
        linesForGlyph = cell(1, height);
        for h = 1:height
            lineRaw = fgetl(fid);
            if ~ischar(lineRaw)
                warning('Reached EOF early for ASCII %d.', asciiCode);
                linesForGlyph{h} = ' ';
            else
                trimmed = regexprep(lineRaw, '\s+$', '');
                trimmed = regexprep(trimmed, '@+$', '');
                linesForGlyph{h} = strrep(trimmed, hardblank, ' ');
            end
        end
        glyphMap(asciiCode) = linesForGlyph;
    end
    
    if ~isKey(glyphMap, 32)
        glyphMap(32) = spaceGlyph;
    end
    
    fclose(fid);

    figletFont.height = height;
    figletFont.hardblank = hardblank;
    figletFont.glyphs = glyphMap;
end

function printFiglet(textString, figletFont)
    glyphMap = figletFont.glyphs;
    height = figletFont.height;
    outLines = repmat({''}, 1, height);

    textString = char(textString);
    for i = 1:length(textString)
        code = double(textString(i));
        if ~isKey(glyphMap, code)
            code = 32;
        end
        linesForGlyph = glyphMap(code);
        for h = 1:height
            outLines{h} = [outLines{h}, linesForGlyph{h}];
        end
    end

    fprintf('\n');
    for h = 1:height
        disp(outLines{h});
    end
    fprintf('\n');
end
