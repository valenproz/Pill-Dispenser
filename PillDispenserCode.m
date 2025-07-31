clear;
clc;
close all;

try
  % For Step 1, initialize all necessary components to make our pill dispenser function

  % Initializes Arduino, servo motor, and tmpSensor
  a = arduino('COM7', 'Leonardo', 'Libraries', 'Servo', 'TMP36');
  s = servo(a, 'D4', 'MinPulseDuration', 700e-6, 'MaxPulseDuration', 2300e-6);
  tmpSensor = addon(a, 'TMP36', 'A1');

  % Initializes MyoWare muscle sensor pin
  musclePin = 'A0';
  THRESHOLD_VALUE = 3.5;

  % Initializes webcam for facial detection
  camera = webcam;
  faceDetector = vision.CascadeObjectDetector();

  angle = 0;
  angleIncrement = 10;
  movementDelay = 50;

  while true
    % Facial detection
    disp("Please face the camera...");
    videoFrame = snapshot(camera);
    bbox = step(faceDetector, videoFrame);

    if ~isempty(bbox)
        muscleValue = readVoltage(a, musclePin);
        if muscleValue > THRESHOLD_VALUE
            disp("Face and muscle contraction detected. Activating pill dispenser.");
            writeDigitalPin(a, 'D12', 0);
            writeDigitalPin(a, 'D13', 1);
            playTone(a, 'D6', 1200);

            newAngle = angle + angleIncrement;
            if newAngle <= 180
                while angle < newAngle
                angle = angle + 1;
                writePosition(s, angle);
                current_pos = readPosition(s);
                current_pos = current_pos *52; % Scales position value
                pause(movementDelay / 1000);
            end
            flashLED(a, 4, 150);
        else
            % Angle has to be precise to ensure that the pill goes through the slot
            while angle > 0
                angle = angle - 1;
                writePosition(s, angle);
                current_pos = readPosition(s);
                current_pos = current_pos * 52;
                pause(movementDelay / 1000);
            end
        end
        disp("Pill Dispensed.");
    else
        disp("Face not detected. Please face the camera.");
    end

    temperature = readVoltage(tmpSensor) * 100;
    disp(['Current Temperature: ' num2str(temperature) 'C']);

    pause(30);
end
catch ME
% Clears the Arduino and camera in case an error occurs
if exist('a', 'var')
    clear a;
end
if exist('camera', 'var')
    clear camera;
end
rethrow(ME);
end
