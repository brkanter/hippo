function installHippo()
    hippoRoot = uigetdir('', 'Select a folder where to install BNT');
    if hippoRoot == 0
        error('You have not selected a folder. Can not continue without it');
    end

    git('clone', 'git@github.com:brkanter/hippo.git', hippoRoot);
    fprintf('Success!\n');

    addpath(hippoRoot);
    try
        savepath;
    catch
        fprintf('Failed to save Matlab''s path to the default location.\nThis is most likely permission issue (no admin rights on your computer).\n');
    end

end