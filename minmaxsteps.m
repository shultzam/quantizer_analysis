function [decisions, reconstructions] = minmaxsteps(reconstructionLevels, x_min, x_max)
    % Create decisions and reconstruction levels based on the given parameters for UNIFORM quantizer.
    % Parameters:
    %   reconstructionLevels - The count of reconstructions required. Must be a positive, real scalar.
    %   x_min - Minimum amplitude value in the audio signal of interest. Must be a scalar.
    %   x_max - Maximum amplitude value in the audio signal of interest. Must be a positive, real scalar.

    % Determine the delta
    delta = ((x_max - x_min) / reconstructionLevels);
    
    % Create the decisions.
    decisions = [x_min + delta];
    for index = 1 : reconstructionLevels - 2
        newValue = decisions(end) + delta;
        decisions = [decisions newValue];
    end

    % Create the reconstructions.
    reconstructions = [x_min + (delta / 2)];
    for index = 1 : reconstructionLevels - 1
        newValue = reconstructions(end) + delta;
        reconstructions = [reconstructions newValue];
    end
end