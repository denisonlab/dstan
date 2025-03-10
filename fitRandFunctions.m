function fitRandFunctions
% this function fits simplified difference of Gamma functions to the output
% from the reverse correlation analysis across different parameter
% combinations (see: testRandomSeq.m) and was run on the BU SCC

% output fits are available on our OSF repository: https://osf.io/qy9pa/

ncores = str2num(getenv("NSLOTS"));
pool = parpool(ncores);

%% do reverse correlation and fit diff of Gammas
t = -3000:5:0;

fitParams = nan(4,100);

r1s = nan(100,length(t)); % sensory layer response
d1s = nan(100,length(t)); % excitatory drive
s1s = nan(100,length(t)); % suppressive drive
f1s = nan(100,length(t)); % normalization factor

parfor ii=1:100
    % for each parameter combination we need to load in the data from the
    % array job
    tempOut = load(sprintf('output/randomSeq/rand_out_%03d.mat',ii),'out');

    % correlate response with stimulus input
    r1_rc = corr(tempOut.out.r1(:,end),tempOut.out.stimList);
    
    % simplified difference of Gammas from Zhou et al (2019) in PLoS Comp Bio
    diffOfGamma = @(t1,t2,w) t.*exp(t./t1) - w.*t.*exp(t./t2);
    funcSSE = @(x) sum((x(4).*diffOfGamma(x(1),x(2),x(3))-r1_rc).^2);

    funcFit = nan(4,100);
    funcVal = nan(1,100);
    
    % fit functions with 100 random starts and pick the best fit
    for rr=1:100
        [tempFit,tempVal] = fminsearch(funcSSE,[randi(900),randi(900),1,1], ...
            optimset('MaxIter',1e5,'MaxFunEvals',1e5,'TolX',1e-12,'TolFun',1e-12));
        funcFit(:,rr) = tempFit;
        funcVal(rr) = tempVal;
    end

    bestFit = funcFit(:,find(funcVal==min(funcVal),1));
    fitParams(:,ii) = bestFit;

    % reverse correlation analysis output for each variable
    r1s(ii,:) = r1_rc;
    d1s(ii,:) = corr(tempOut.out.d1(:,end),tempOut.out.stimList);
    s1s(ii,:) = corr(tempOut.out.s1(:,end),tempOut.out.stimList);
    f1s(ii,:) = corr(tempOut.out.f1(:,end),tempOut.out.stimList);
end

rc_out.fitParams = fitParams;
rc_out.r1 = r1s;
rc_out.d1 = d1s;
rc_out.s1 = s1s;
rc_out.f1 = f1s;

save('output/revCorFits.mat','rc_out');
