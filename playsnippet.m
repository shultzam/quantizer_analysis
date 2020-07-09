function playsnippet(audio, sampleRate, audioType)
    % Plays a snippet of the given audio data.
    % Parameters:
    %   audio - Audio signal. Must be a vector or array.
    %   sampleRate - Sampling frequency. Must be a positive, real scalar.
    %   audioType - String to be print prior to playing the snippet. Must be a string.

    % Error checks.
    if (isempty(audio) || ~isreal(audio))
        error('Invalid audio given to playsnippet().'); 
    end
    
    mustBePositive(sampleRate);
    
    if (isempty(audioType))
        error('Invalid audioType given to playsnippet().'); 
    end

    soundplayer = audioplayer(audio, sampleRate);
    fprintf('Click plot to play %s..\n', audioType);
    w = waitforbuttonpress;
    play(soundplayer);
    fprintf('Click plot to stop.\n');
    w = waitforbuttonpress;
    stop(soundplayer);
end