clear,clc

Ns = 1; % # of streams

Ncl = 1; % # of clusters
Nray = 1; % # of rays in each cluster

Nt = 16; % # of transmit antennas
Nr = 16; % # of receive antennas

angle_sigma = 7.5/180*pi; %standard deviation of the angles in azimuth and elevation both of Rx and Tx

gamma = sqrt((Nt*Nr)/(Ncl*Nray)); %normalization factor
sigma = 1; %according to the normalization condition of the H
rho = 0.995; % correlation coefficient of complex path gain

realization = 2000;
% realization = 2; %ONLY FOR SANITY CHECK
K = 100; % Total length of iterations (state evolution)
% K = 2; %ONLY FOR SANITY CHECK

count = 0; %Dummy counting variable for channel rank constraint >= N_S

for reali = 1:realization
    % k == 1 (initial channel of each realization)
    for c = 1:Ncl
        AoD_m = unifrnd(0,2*pi,1,2);
        AoA_m = unifrnd(0,2*pi,1,2);
        AoD(1,[(c-1)*Nray+1:Nray*c]) = laprnd(1,Nray,AoD_m(1),angle_sigma);
        AoA(1,[(c-1)*Nray+1:Nray*c]) = laprnd(1,Nray,AoA_m(1),angle_sigma);
    end
    
    H(:,:,reali,1) = zeros(Nr,Nt);
    for j = 1:Ncl*Nray
        At(:,j,reali,1) = array_response_ULA(AoD(1,j),Nt); %ULA array response
        Ar(:,j,reali,1) = array_response_ULA(AoA(1,j),Nr);
        alpha(j,reali,1) = normrnd(0,sqrt(sigma/2)) + normrnd(0,sqrt(sigma/2))*sqrt(-1);
        H(:,:,reali,1) = H(:,:,reali,1) + alpha(j,reali,1) * Ar(:,j,reali,1) * At(:,j,reali,1)';
    end
    H(:,:,reali,1) = gamma * H(:,:,reali,1);
    
    if(rank(H(:,:,reali,1))>=Ns)
        count = count + 1;
        
        [U,S,V] = svd(H(:,:,reali,1));
        Fopt(:,:,reali) = V([1:Nt],[1:Ns]);
        Wopt(:,:,reali) = U([1:Nr],[1:Ns]);
    end
    
    % k is 2 and greater; complex path gain, AoA, and AoD follow the
    % recurrence relation by its preceding value in iteration
    for k = 2:K
        H(:,:,reali,k) = zeros(Nr,Nt);
        for j = 1:Ncl*Nray
        AoA(1,j) = AoA(1,j) + normrnd(0,0.5); % Angular variation 0.5
        AoD(1,j) = AoD(1,j) + normrnd(0,0.5); % Angular variation 0.5
        At(:,j,reali,k) = array_response_ULA(AoD(1,j),Nt); %ULA array response
        Ar(:,j,reali,k) = array_response_ULA(AoA(1,j),Nr);
        alpha(j,reali,k) = rho*alpha(j,reali,k-1) + normrnd(0,(1-rho)^2/2) + normrnd(0,(1-rho)^2/2)*sqrt(-1);
        H(:,:,reali,k) = H(:,:,reali,k) + alpha(j,reali,k) * Ar(:,j,reali,k) * At(:,j,reali,k)';
        end
        
        if(rank(H(:,:,reali,k))>=Ns)
            count = count + 1;
            
            [U,S,V] = svd(H(:,:,reali,k));
            Fopt(:,:,reali) = V([1:Nt],[1:Ns]);
            Wopt(:,:,reali) = U([1:Nr],[1:Ns]);
        end
    end
end