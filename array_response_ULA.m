function y = array_response_ULA(a1,N)
%Modified by Dohyun Kim
%Address 2^{n} number of antennas

% if floor(sqrt(N))==sqrt(N) %If N is 2^{2n} for some integer n
%     % Set UPA as 2^n * 2^n
%     range_of_m = sqrt(N)-1;
%     range_of_n = sqrt(N)-1;
%     index_parameter = sqrt(N);
% else %else if N is 2^{2n+1} for some integer n
%     % Set UPA as 2^n * 2^(n+1)
%     range_of_m = 2^((log2(N)-1)/2)-1;
%     range_of_n = 2^((log2(N)+1)/2)-1;
%     index_parameter = 2^((log2(N)+1)/2);
% end

for m= 0:N-1
    y(m+1) = exp( 1i* pi* ( m*sin(a1) ) );
end
y = y.'/sqrt(N);


%%% Original code for UPA
% for m= 0:sqrt(N)-1
%     for n= 0:sqrt(N)-1
%         y(m*(sqrt(N))+n+1) = exp( 1i* pi* ( m*sin(a1)*sin(a2) + n*cos(a2) ) );
%     end
% end
% y = y.'/sqrt(N);
end