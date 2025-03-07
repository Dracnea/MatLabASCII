function renderFigletText(textString, fontFile)
    persistent fontCache;
    
    if isempty(fontCache)
        fontCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    fontFile = sanitizeFileName(fontFile);
    
    if isKey(fontCache, fontFile)
        figletFont = fontCache(fontFile);
    else
        fontFile = downloadIfURL(fontFile);
        figletFont = loadFigletFont(fontFile);
        fontCache(fontFile) = figletFont;
    end
    
    printFiglet(textString, figletFont);
end

% URL Downloads are still buggy based on where they are being downloaded from, often saved as .html
function localFile = downloadIfURL(filePath)
    if startsWith(filePath, 'http')
        [scriptPath, ~, ~] = fileparts(mfilename('fullpath'));
        [~, name, ext] = fileparts(filePath);
        
        if isempty(ext) || ~strcmp(ext, '.flf')
            ext = '.flf';
        end
        
        localFile = fullfile(scriptPath, [name, ext]);
        websave(localFile, filePath);
        
        % Check if the downloaded file is actually an HTML file (error page)
        if isHTMLFile(localFile) || ~isValidFigletFile(localFile)
            delete(localFile);
            error('Downloaded file is not a valid FIGlet .flf file. Ensure you are using a raw .flf file link.');
        end
    else
        localFile = sanitizeFileName(filePath);
    end
end

function sanitizedName = sanitizeFileName(filePath)
    [~, name, ~] = fileparts(filePath);
    sanitizedName = strcat(name, '.flf');
end

function isHTML = isHTMLFile(filePath)
    fid = fopen(filePath, 'r');
    if fid < 0
        isHTML = false;
        return;
    end
    firstLine = fgetl(fid);
    fclose(fid);
    isHTML = contains(firstLine, '<!DOCTYPE html>') || contains(firstLine, '<html>');
end

function isValid = isValidFigletFile(filePath)
    fid = fopen(filePath, 'r');
    if fid < 0
        isValid = false;
        return;
    end
    
    firstLine = fgetl(fid);
    fclose(fid);
    
    isValid = ischar(firstLine) && startsWith(firstLine, 'flf2a');
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

function cleanUpFLFFiles()
    [scriptPath, ~, ~] = fileparts(mfilename('fullpath'));
    flfFiles = dir(fullfile(scriptPath, '*.flf'));
    for i = 1:length(flfFiles)
        delete(fullfile(scriptPath, flfFiles(i).name));
    end
    fprintf('All .flf files have been deleted from the script directory.\n');
end
