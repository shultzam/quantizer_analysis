% Speech files live at: 
%   - https://www.americanrhetoric.com/barackobamaspeeches.htm, titled barackobamatransitionaddress10.mp3 or
%     "10th President-Elect Weekly Transition Address". This audio is crystal clear to the naked ear. Length of 303s.
%   - https://www.americanrhetoric.com/top100speechesall.html, titled ronaldreaganchallengeraddress.mp3 or
%     "Shuttle 'Challenger' Disaster Address". This audio is pretty noisy. Length of 251s.
% Requires: 
%   - Signal Processing Toolbox - for audioread()
%   - Communications Toolbox - for quantiz()

% Clear terminal and variables.
clc;
close all;
clearvars;
clearvars global;

% Read in the full audio data in .wav format.
%originalFileName = 'barackobamatransitionaddress10.wav';
originalFileName = 'ronaldreaganchallengeraddress.wav';
originalFileSize = dir(originalFileName).bytes;
fprintf('Original audio fileSize: %u bytes.\n', originalFileSize);
[audioData, sampleRate] = audioread(originalFileName);

% Plot the analog waveform.
deltaTime = 1/sampleRate;
time = 0:deltaTime:(length(audioData) * deltaTime) - deltaTime;
figure(1);
subplot(7, 1, 1);
plot(time, audioData, 'r'); axis tight; grid on; 
title('Original audio amplitude over time.'); xlabel('Seconds'); ylabel('Amplitude');

% Perform uniform scalar quantization (on each channel separately). Where decision levels DO NOT consider maximum value
% of the sequence.
%   Amplitude falls in range [-1, 1].
%   8 reconstruction levels. 2^3 = 8, so 3 bits in coding.
%   Delta:
%      0.25
%   Decision levels: 
%      [-3/4, -1/2, -1/4, 0, 1/4, 1/2, 3/4]
%   Reconstruction levels: 
%      [-7/8, -5/8, -3/8, -1/8, 1/8, 3/8, 5/8, 7/8]
decisions = [-0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75];
reconstructions = [-0.875, -0.625, -0.375, -0.125, 0.125, 0.375, 0.625, 0.875];
[~, quantsChannelOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[~, quantsChannelTwo, msDistortion2] = quantiz(audioData(:, 2), decisions, reconstructions);
quants = [quantsChannelOne(:), quantsChannelTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the uniformly quantized waveform.
subplot(7, 1, 2);
plot(time, quants, 'b'); axis tight; grid on;
title(sprintf('Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion)); 
xlabel('Seconds'); ylabel('Quantized Amplitude');

% Perform uniform scalar quantization (on each channel separately). Where decision levels DO consider maximum value of 
% the sequence and an extra bit is used in coding.
%   Amplitude falls in range [-1, 1].
%   8 reconstruction levels. 2^3 = 8, so 3 bits in coding.
%   Delta:
%      (x_max-x_min)/2^B
%   Decision levels: 
%      determined based on x_min, x_max and reconstruction levels count
%   Reconstruction levels: 
%      determined based on x_min, x_max and reconstruction levels count
% Generate decisions and reconstructions.
reconstructionLevels = 8;
x_min = min(audioData(:, 1));
x_max = max(audioData(:, 1));
[decisions, reconstructions] = minmaxsteps(reconstructionLevels, x_min, x_max);

[indexes3Bits1, quantsChannelOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[indexes3Bits2, quantsChannelTwo, msDistortion2] = quantiz(audioData(:, 2), decisions, reconstructions);
indexes3Bits = uint8([indexes3Bits1(:), indexes3Bits2(:)]);
codebook3Bits = reconstructions;
improvedQuants = [quantsChannelOne(:), quantsChannelTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the improved uniformly quantized waveform.
subplot(7, 1, 3);
plot(time, improvedQuants, 'g'); axis tight; grid on;
title(sprintf('Improved Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion)); 
xlabel('Seconds'); ylabel('Quantized Amplitude');

% Perform uniform scalar quantization (on each channel separately) using extra bits. Where decision levels DO consider 
% maximum value of the sequence.
%   Amplitude falls in range [-1, 1].
%   16 reconstruction levels. 2^8 = 256, so 8 bits in coding.
%   Delta:
%      determined by minmaxsteps
%   Decision levels: 
%      determined by minmaxsteps
%   Reconstruction levels: 
%      determined by minmaxsteps
%
% Generate decisions and reconstructions.
reconstructionLevels = 256;
x_min = min(audioData(:, 1));
x_max = max(audioData(:, 1));
[decisions, reconstructions] = minmaxsteps(reconstructionLevels, x_min, x_max);

[indexes8Bits1, quantsChannelOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[indexes8Bits2, quantsChannelTwo, msDistortion2] = quantiz(audioData(:, 2), decisions, reconstructions);
indexes8Bits = uint8([indexes8Bits1(:), indexes8Bits2(:)]);
codebook8Bits = reconstructions;
improvedQuantsExtended = [quantsChannelOne(:), quantsChannelTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the improved and extended uniformly quantized waveform.
subplot(7, 1, 4);
plot(time, improvedQuantsExtended, 'm'); axis tight; grid on;
title(sprintf('Improved/Extended Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion));
xlabel('Seconds'); ylabel('Quantized Amplitude');

% Perform non-uniform scalar quantization (on each channel separately). 
%   Amplitude falls in range [-1, 1].
%   8 reconstruction levels. 2^3 = 16, so 3 bits in coding.
%   Delta:
%      determined by quantiles
%   Decision levels: 
%      determined by quantiles
%   Reconstruction levels: 
%      determined by quantiles
%
% Generate decisions and reconstructions.
reconstructionLevels = 8;
decisions = quantile(audioData(:, 1), reconstructionLevels - 1);
reconstructions = [(-1.0 - decisions(1)) / 2];
for index = 2 : reconstructionLevels - 1
    newValue = (decisions(index) - decisions(index-1))/2;
    reconstructions = [reconstructions newValue];
end
reconstructions = [reconstructions ((1.0 - reconstructions(end)) / 2)];

[~, quantsChannelOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[~, quantsChannelTwo, msDistortion2] = quantiz(audioData(:, 2), decisions, reconstructions);
nonUniformQuants = [quantsChannelOne(:), quantsChannelTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the non-uniformly quantized waveform.
subplot(7, 1, 5);
plot(time, nonUniformQuants, 'k'); axis tight; grid on;
title(sprintf('Non-Uniform Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion));
xlabel('Seconds'); ylabel('Quantized Amplitude');

% Perform non-uniform scalar quantization (on each channel separately). An extra bit is used in coding.
%   Amplitude falls in range [-1, 1].
%   8 reconstruction levels. 2^8 = 256, so 8 bits in coding.
%   Delta:
%      determined by quantiles
%   Decision levels: 
%      determined by quantiles
%   Reconstruction levels: 
%      determined by quantiles
%
% Generate decisions and reconstructions.
reconstructionLevels = 256;
decisions = quantile(audioData(:, 1), reconstructionLevels - 1);
reconstructions = [(-1.0 - decisions(1)) / 2];
for index = 2 : reconstructionLevels - 1
    newValue = (decisions(index) - decisions(index-1))/2;
    reconstructions = [reconstructions newValue];
end
reconstructions = [reconstructions ((1.0 - reconstructions(end)) / 2)];

[~, quantsChannelOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[~, quantsChannelTwo, msDistortion2] = quantiz(audioData(:, 2), decisions, reconstructions);
nonUniformQuantsExtended = [quantsChannelOne(:), quantsChannelTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the non-uniformly quantized waveform.
subplot(7, 1, 6);
plot(time, nonUniformQuantsExtended, 'k'); axis tight; grid on;
title(sprintf('Extended Non-Uniform Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion));
xlabel('Seconds'); ylabel('Quantized Amplitude');

% For comparison's sake, use the Lloyd Algorithm [lloyd()] to optimize the quantization parameters with 3-bits.
reconstructionLevels = 8;
[decisions, reconstructions] = lloyds(audioData(:, 1), reconstructionLevels);
[~, lloydsQuantsOne, msDistortion1] = quantiz(audioData(:, 1), decisions, reconstructions);
[~, lloydsQuantsTwo, msDistortion2] = quantiz(audioData(:, 1), decisions, reconstructions);
lloydsQuants = [lloydsQuantsOne(:), lloydsQuantsTwo(:)];
ms_distortion = (msDistortion1 + msDistortion2) / 2;

% Plot the Lloyd's optimized non-uniformly quantized waveform.
subplot(7, 1, 7);
plot(time, lloydsQuants, 'c'); axis tight; grid on;
title(sprintf('Lloyd''s Quantized Amplitude Over Time. Distortion: %.5f', ms_distortion));
xlabel('Seconds'); ylabel('Quantized Amplitude');

% Plot the original audio against the 3-bit and 8-bit uniform quantized waveforms.
figure(2);
fifteenSeconds = 15 * sampleRate;
plot(time(1:fifteenSeconds), audioData(1:fifteenSeconds), 'r', ...
     time(1:fifteenSeconds), improvedQuants(1:fifteenSeconds), 'c', ...
     time(1:fifteenSeconds), improvedQuantsExtended(1:fifteenSeconds), 'b'); 
axis tight; grid on;
title(sprintf('Original Audo Compared to 3-Bit and 8-bit Quantizers (15s)'));
xlabel('Seconds'); ylabel('Amplitudes'); legend('Original Audio', '3-Bit Uniform Quantizer', '8-bit Uniform Quantizer');

%%%  Audio play %%%

% Play the original audio file.
playsnippet(audioData, sampleRate, 'original audio');

% Play the uniform quantized audio.
playsnippet(quants, sampleRate, 'uniform quantized audio');

% Play the improved uniform quantized audio. 3-bits.
playsnippet(improvedQuants, sampleRate, 'improved uniform quantized audio');

% Play the improved and extended uniform quantized audio. 8-bits.
playsnippet(improvedQuantsExtended, sampleRate, 'improved/extended uniform quantized audio');

% Play the non-uniformquantized audio. 3-bits.
playsnippet(nonUniformQuants, sampleRate, 'non-uniform quantized audio');

% Play the non-uniformquantized audio. 8-bits.
playsnippet(nonUniformQuantsExtended, sampleRate, 'extended non-uniform quantized audio');

% Play the lloyd optimized quantized audio.
playsnippet(lloydsQuants, sampleRate, 'Lloyd optimized quantized audio');

%%% File Writes for Size Checks %%%

% Write 3-bit coding to disk.
frameSize = size(indexes3Bits, 1);
numChannels = size(indexes3Bits, 2);
header = struct('DataType', 'uint8', 'Complexity', false, 'FrameSize', frameSize, 'NumChannels', numChannels);
[~, threeBitCodedFileName, ~] = fileparts(originalFileName);
threeBitCodedFileName = append(threeBitCodedFileName, '-3Bits.bin');
writer = dsp.BinaryFileWriter(threeBitCodedFileName, 'HeaderStructure', header);
writer(indexes3Bits);
release(writer);

% Read the 3-bit coded file size.
threeBitFileSize = dir(threeBitCodedFileName).bytes;
fprintf('3-bit coded audio fileSize: %u bytes.\n', threeBitFileSize);

% Write the 3-bit codebook to disk.
[~, threeBitCodebookFileName, ~] = fileparts(originalFileName);
threeBitCodebookFileName = append(threeBitCodebookFileName, '-3BitCodebook.txt');
fileId = fopen(threeBitCodebookFileName, 'w');
fprintf(fileId, '%f\n', codebook3Bits);
fclose(fileId);

% Convert indexes back into quants and check if the reconstructed quants are identical to the original 3-bit quants.
reconstructed3BitQuants = double(indexes3Bits);
for index = 1 : length(codebook3Bits)
    reconstructed3BitQuants(reconstructed3BitQuants == (index - 1)) = codebook3Bits(index);
end
fprintf('Reconstructed 3-bit quants are identical to improvedQuants: %u\n', isequal(reconstructed3BitQuants, ...
                                                                                    improvedQuants));

% Write 8-bit coding to disk.
frameSize = size(indexes8Bits, 1);
numChannels = size(indexes8Bits, 2);
header = struct('DataType', 'uint8', 'Complexity', false, 'FrameSize', frameSize, 'NumChannels', numChannels);
[~, fourBitCodedFileName, ~] = fileparts(originalFileName);
fourBitCodedFileName = append(fourBitCodedFileName, '-8Bits.bin');
writer = dsp.BinaryFileWriter(fourBitCodedFileName, 'HeaderStructure', header);
writer(indexes8Bits);
release(writer);

% Read the 8-bit coded file size.
fourBitFileSize = dir(fourBitCodedFileName).bytes;
fprintf('8-bit coded audio fileSize: %u bytes.\n', fourBitFileSize);

% Write the 8-bit codebook to disk.
[~, fourBitCodebookFileName, ~] = fileparts(originalFileName);
fourBitCodebookFileName = append(fourBitCodebookFileName, '-8bitCodebook.txt');
fileId = fopen(fourBitCodebookFileName, 'w');
fprintf(fileId, '%f\n', codebook8Bits);
fclose(fileId);

% Convert indexes back into quants and check if the reconstructed quants are identical to the original 8-bit quants.
reconstructed8BitQuants = double(indexes8Bits);
for index = 1 : length(codebook8Bits)
    reconstructed8BitQuants(reconstructed8BitQuants == (index - 1)) = codebook8Bits(index);
end
fprintf('Reconstructed 8-bit quants are identical to improvedQuantsExtended: %u\n', isequal(reconstructed8BitQuants, ...
                                                                                            improvedQuantsExtended));
                                                                                
