function [assets_temp_move, move, cons_eqiv] = work_fare(grid, params,shocks,tmat,value_funs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This solves for the policy functions for the field experiment. The idea
% is to take the optimal value functions, then solve for the optimal policy
% functions given the one time move. See the notes for more description.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

R = params(1); 
z_rural = params(2); z_urban = params(3); 

beta = params(4); m = params(5); gamma = params(6); abar = params(7);

ubar = params(8); lambda = params(9); pi_prob = params(11);

m_seasn = params(10);

shocks_rural = shocks(:,1); shocks_urban = shocks(:,2);
trans_mat = tmat;

n_shocks = length(shocks_rural);

A = (1-gamma).^-1;

v_hat_rural_not  = value_funs(:,:,1);
v_hat_rural_exp  = value_funs(:,:,2);

v_hat_seasn_not = value_funs(:,:,3);
v_hat_seasn_exp = value_funs(:,:,4);

v_hat_urban_new  = value_funs(:,:,5);
v_hat_urban_old  = value_funs(:,:,6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up grid for asset holdings. This is the same across locations.
n_asset_states = grid(1);

asset_space = linspace(grid(2),grid(3),grid(1));
% asset_space = [0, logspace(log10(grid(2)),log10(grid(3)),n_asset_states-1)];

asset_grid  = meshgrid(asset_space,asset_space);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up the matricies for value function itteration. Note that there is a
% value associated with each state: (i) asset (ii) shock (iii) location. 
% The third one is the new one...

policy_assets_rural_not = zeros(n_asset_states,n_shocks);
policy_move_rural_not = zeros(n_asset_states,n_shocks);

policy_assets_rural_exp = zeros(n_asset_states,n_shocks);
policy_move_rural_exp = zeros(n_asset_states,n_shocks);

v_expr_rural_not = zeros(n_asset_states,n_shocks);
v_expr_rural_exp = zeros(n_asset_states,n_shocks);

u_opt_not = zeros(n_asset_states,n_shocks);
u_opt_exp = zeros(n_asset_states,n_shocks);
% This is the period utility function when confronted with the transfer.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preallocate stuff that stays fixed (specifically potential period utility and
% net assets in the maximization routine....

utility_rural = zeros(n_asset_states,n_asset_states,n_shocks);
utility_move_seasn = zeros(n_asset_states,n_asset_states,n_shocks);
utility_move_rural = zeros(n_asset_states,n_asset_states,n_shocks);


feasible_rural = false(n_asset_states,n_asset_states,n_shocks);
feasible_move_rural = false(n_asset_states,n_asset_states,n_shocks);
feasible_move_seasn = false(n_asset_states,n_asset_states,n_shocks);

net_assets = R.*asset_grid' - asset_grid;

cash_transfer = 0.75.*m_seasn;

for zzz = 1:n_shocks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    consumption = (net_assets + cash_transfer) + z_rural.*shocks_rural(zzz) - abar;
    % Only GET the transfer if you STAY AND WORK!!!
    
    feasible_rural(:,:,zzz) = consumption > 0;
    
    utility_rural(:,:,zzz) = A.*(max(consumption,1e-10)).^(1-gamma);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    consumption = (net_assets) + z_rural.*shocks_rural(zzz) - abar - m_seasn;
    % NO TRANSFER YOU ARE MOVING
    
    feasible_move_seasn(:,:,zzz) = consumption > 0;
    
    utility_move_seasn(:,:,zzz) = A.*(max(consumption,1e-10)).^(1-gamma);
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    consumption = (net_assets) + z_rural.*shocks_rural(zzz) - m - abar;
    % NO TRANSFER YOU ARE MOVING
    
    feasible_move_rural(:,:,zzz) = consumption > 0;
    
    utility_move_rural(:,:,zzz) = A.*(max(consumption,1e-10)).^(1-gamma) ;
             
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Note that ubar or urban shocks to not show up anywhere here. Why? because
%of the timing, the ubar is all built into the value functions of seasonal
%move and the ubran more. 

for zzz = 1:n_shocks
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
    expected_value_rural_not = beta.*(trans_mat(zzz,:)*v_hat_rural_not');
    
    expected_value_rural_exp = beta.*(trans_mat(zzz,:)*v_hat_rural_exp');
        
    expected_value_urban_new = beta.*(trans_mat(zzz,:)*v_hat_urban_new');
    
    expected_value_urban_old = beta.*(trans_mat(zzz,:)*v_hat_urban_old');
    
    expected_value_seasn_not = beta.*(trans_mat(zzz,:)*v_hat_seasn_not');
    
    expected_value_seasn_exp = beta.*(trans_mat(zzz,:)*v_hat_seasn_exp');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           NOT-EXPERIENCED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the value of being in the rural area...

    value_fun = bsxfun(@plus,utility_rural(:,:,zzz),expected_value_rural_not);
    
    value_fun(~feasible_rural(:,:,zzz)) = -1e10;
    
    [v_stay_rural_not, p_asset_stay_rural_not] = max(value_fun,[],2);
    
    u_rural = diag(utility_rural(:,p_asset_stay_rural_not,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the value of being being a seasonal migrant...NOTE NO MOVING COST
% HERE THIS IS THE EXPERIMENT

    value_fun = bsxfun(@plus,utility_move_seasn(:,:,zzz),expected_value_seasn_not);
    
    value_fun(~feasible_move_seasn(:,:,zzz)) = -1e10;
    
    [v_move_seasn_not, p_asset_move_seasn_not] = max(value_fun,[],2);
    
    u_move_seasn = diag(utility_move_seasn(:,p_asset_move_seasn_not,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute value of moving...here I get the expected value of being in the
% urban area because I'm moving out the rural area and I become a new guy.

    value_fun = bsxfun(@plus, utility_move_rural(:,:,zzz) , expected_value_urban_new);
    
    value_fun(~feasible_move_rural(:,:,zzz)) = -1e10;
       
    [v_move_rural_not, p_asset_move_rural_not] = max(value_fun,[],2);
    
    u_move_rural = diag(utility_move_rural(:,p_asset_move_rural_not,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p_asset_stay_rural_all_not = [ p_asset_stay_rural_not , p_asset_move_seasn_not , p_asset_move_rural_not ];
       
    [v_expr_rural_not(:,zzz), policy_move_rural_not(:,zzz)] = max([ v_stay_rural_not , v_move_seasn_not, v_move_rural_not],[],2) ;

    policy_assets_rural_not(:,zzz) = diag(p_asset_stay_rural_all_not(:, policy_move_rural_not(:,zzz)));
    
    u_all_not = [u_rural, u_move_seasn, u_move_rural];
    
    u_opt_not(:,zzz) = diag(u_all_not(:,policy_move_rural_not(:,zzz)));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           EXPERIENCED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the value of being in the rural area...

    value_fun = bsxfun(@plus, utility_rural(:,:,zzz),...
        pi_prob.*expected_value_rural_exp + (1-pi_prob).*expected_value_rural_not);
    
    value_fun(~feasible_rural(:,:,zzz)) = -1e10;
    
    [v_stay_rural_exp, p_asset_stay_rural_exp] = max(value_fun,[],2);
    
    u_rural = diag(utility_rural(:,p_asset_stay_rural_exp,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the value of being being a seasonal migrant...

    value_fun = bsxfun(@plus, utility_move_seasn(:,:,zzz),...
        pi_prob.*expected_value_seasn_exp + (1-pi_prob).*expected_value_seasn_not);
    
    value_fun(~feasible_move_seasn(:,:,zzz)) = -1e10;
    
    [v_move_seasn_exp, p_asset_move_seasn_exp] = max(value_fun,[],2);
    
    u_move_seasn = diag(utility_move_seasn(:,p_asset_move_seasn_exp,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute value of moving...here I get the expected value of being in the
% urban area because I'm moving out the rural area and I become a new guy.

    value_fun = bsxfun(@plus, utility_move_rural(:,:,zzz) , ...
        pi_prob.*expected_value_urban_old + (1-pi_prob).*expected_value_urban_new);
    
    value_fun(~feasible_move_rural(:,:,zzz)) = -1e10;
       
    [v_move_rural_exp, p_asset_move_rural_exp] = max(value_fun,[],2);
    
    u_move_rural = diag(utility_move_rural(:,p_asset_move_rural_exp,zzz));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    p_asset_stay_rural_all_e = [ p_asset_stay_rural_exp , p_asset_move_seasn_exp , p_asset_move_rural_exp ];
            
    [v_expr_rural_exp(:,zzz), policy_move_rural_exp(:,zzz)] = max([ v_stay_rural_exp , v_move_seasn_exp, v_move_rural_exp],[],2) ;

    policy_assets_rural_exp(:,zzz) = diag(p_asset_stay_rural_all_e(:, policy_move_rural_exp(:,zzz)));
    
    u_all_exp = [u_rural, u_move_seasn, u_move_rural];
    
    u_opt_exp(:,zzz) = diag(u_all_exp(:,policy_move_rural_exp(:,zzz)));

end

assets_temp_move = zeros(n_asset_states,n_shocks,2);
move = zeros(n_asset_states,n_shocks,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This generates the permenant percent increse... uncomment the first line
% to get the ``gift of experince'' result

% cons_eqiv(:,:,1) = ((v_expr_rural_not./v_hat_rural_not)).^(1./(1-gamma)) - 1;
% cons_eqiv(:,:,2) = ((v_expr_rural_exp./v_hat_rural_exp)).^(1./(1-gamma)) - 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This generates the one time equivalent variation...

cons_eqiv(:,:,1) = (((v_expr_rural_not-v_hat_rural_not)./u_opt_not + 1)).^(1./(1-gamma))- 1;
cons_eqiv(:,:,2) = (((v_expr_rural_exp-v_hat_rural_exp)./u_opt_exp + 1)).^(1./(1-gamma))- 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assets_temp_move(:,:,1) = policy_assets_rural_not;
assets_temp_move(:,:,2) = policy_assets_rural_exp;

move(:,:,1) = policy_move_rural_not;
move(:,:,2) = policy_move_rural_exp;

% These are the asset policies that are associated with the temporary move
% The moving policies. 








