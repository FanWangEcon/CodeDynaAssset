%% Risky + Safe Asset Dyna Prog Concurrent Solution (Optimized-Vectorized)
% *back to <https://fanwangecon.github.io Fan>'s
% <https://fanwangecon.github.io/CodeDynaAsset/ Dynamic Assets Repository> 
% Table of Content.*

%%
function result_map = ff_akz_vf_vecsv(varargin)
%% FF_AKZ_VF_VECSV solve infinite horizon exo shock + endo asset problem
% This program solves the infinite horizon dynamic savings and risky
% capital asset problem with some shocks. This is the optimized-vectorized version
% of
% <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_akz_vf.html
% ff_akz_vf>. See that file for more descriptions. See
% <https://fanwangecon.github.io/CodeDynaAsset/m_az/solve/html/ff_az_vf_vecsv.html
% ff_az_vf_vecsv> for the idea for optimized-vectorized code. This file
% here is meant to handle savings only or borrowing (without default) will
% also work as well.
% <https://fanwangecon.github.io/CodeDynaAsset/m_akbz/solve/html/ff_akbz_vf_vecsv.html
% ff_akbz_vf_vecsv> version of this code deals with borrowing as well.
%
% @param param_map container parameter container
%
% @param support_map container support container
%
% @param armt_map container container with states, choices and shocks
% grids that are inputs for grid based solution algorithm
%
% @param func_map container container with function handles for
% consumption cash-on-hand etc.
%
% @return result_map container contains policy function matrix, value
% function matrix, iteration results, and policy function, value function
% and iteration results tables. 
%
% keys included in result_map:
%
% * mt_val matrix states_n by shock_n matrix of converged value function grid
% * mt_pol_a matrix states_n by shock_n matrix of converged policy function
% grid safe asset
% * mt_pol_k matrix states_n by shock_n matrix of converged policy function
% grid risky asset
% * ar_val_diff_norm array if bl_post = true it_iter_last by 1 val function
% difference between iteration
% * ar_pol_diff_norm array if bl_post = true it_iter_last by 1 policy
% function difference between iterations
% * mt_pol_perc_change matrix if bl_post = true it_iter_last by shock_n the
% proportion of grid points at which policy function changed between
% current and last iteration for each element of shock
%
% @example
%
%   it_param_set = 2;
%   [param_map, support_map] = ffs_akz_set_default_param(it_param_set);   
%   % Simulation Accuracy
%   param_map('it_w_n') = 750;
%   param_map('it_ak_n') = param_map('it_w_n');
%   param_map('it_z_n') = 11;
%   % Display Parameters
%   support_map('bl_display') = false;
%   support_map('bl_display_final') = false;
%   support_map('bl_time') = true;
%   support_map('bl_profile') = false;
%   % Call Program with external parameters that override defaults
%   ff_akz_vf_vecsv(param_map, support_map);
% 
% @include
%
% * <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_set_default_param.html ffs_akz_set_default_param>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_get_funcgrid.html ffs_akz_get_funcgrid>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solvepost/html/ff_akz_vf_post.html ff_akz_vf_post>
%
% @seealso
%
% * concurrent (safe + risky) loop: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_akz_vf.html ff_akz_vf>
% * concurrent (safe + risky) vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_akz_vf_vec.html ff_akz_vf_vec>
% * concurrent (safe + risky) optimized-vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_akz_vf_vecsv.html ff_akz_vf_vecsv>
% * two-stage (safe + risky) loop: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_wkz_vf.html ff_wkz_vf>
% * two-stage (safe + risky) vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_wkz_vf_vec.html ff_wkz_vf_vec>
% * two-stage (safe + risky) optimized-vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_wkz_vf_vecsv.html ff_wkz_vf_vecsv>
% * two-stage + interpolate (safe + risky) loop: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_iwkz_vf.html ff_iwkz_vf>
% * two-stage + interpolate (safe + risky) vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_iwkz_vf_vec.html ff_iwkz_vf_vec>
% * two-stage + interpolate (safe + risky) optimized-vectorized: <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_iwkz_vf_vecsv.html ff_iwkz_vf_vecsv>
%

%% Default
% * it_param_set = 1: quick test
% * it_param_set = 2: benchmark run
% * it_param_set = 3: benchmark profile
% * it_param_set = 4: press publish button

it_param_set = 4;
[param_map, support_map] = ffs_akz_set_default_param(it_param_set);

% Note: param_map and support_map can be adjusted here or outside to override defaults
% param_map('it_w_n') = 50;
% param_map('it_z_n') = 15;

% get armt and func map
[armt_map, func_map] = ffs_akz_get_funcgrid(param_map, support_map); % 1 for override
default_params = {param_map support_map armt_map func_map};

%% Parse Parameters 1

% if varargin only has param_map and support_map,
params_len = length(varargin);
[default_params{1:params_len}] = varargin{:};
param_map = [param_map; default_params{1}];
support_map = [support_map; default_params{2}];
if params_len >= 1 && params_len <= 2
    % If override param_map, re-generate armt and func if they are not
    % provided
    [armt_map, func_map] = ffs_akz_get_funcgrid(param_map, support_map);
else
    % Override all
    armt_map = [armt_map; default_params{3}];
    func_map = [func_map; default_params{4}];
end

% append function name
st_func_name = 'ff_akz_vf_vecsv';
support_map('st_profile_name_main') = [st_func_name support_map('st_profile_name_main')];
support_map('st_mat_name_main') = [st_func_name support_map('st_mat_name_main')];
support_map('st_img_name_main') = [st_func_name support_map('st_img_name_main')];

%% Parse Parameters 2

% armt_map
params_group = values(armt_map, {'mt_z_trans', 'ar_z'});
[ mt_z_trans, ar_z] = params_group{:};
params_group = values(armt_map, {'ar_a_meshk', 'ar_k_mesha', 'mt_coh_wkb', 'it_ameshk_n'});
[ar_a_meshk, ar_k_mesha, mt_coh_wkb, it_ameshk_n] = params_group{:};
% func_map
params_group = values(func_map, {'f_util_log', 'f_util_crra', 'f_cons', 'f_coh'});
[f_util_log, f_util_crra, f_cons, f_coh] = params_group{:};
% param_map
params_group = values(param_map, {'it_z_n', 'fl_crra', 'fl_beta', 'fl_c_min'});
[it_z_n, fl_crra, fl_beta, fl_c_min] = params_group{:};
params_group = values(param_map, {'it_maxiter_val', 'fl_tol_val', 'fl_tol_pol', 'it_tol_pol_nochange'});
[it_maxiter_val, fl_tol_val, fl_tol_pol, it_tol_pol_nochange] = params_group{:};
% support_map
params_group = values(support_map, {'bl_profile', 'st_profile_path', ...
    'st_profile_prefix', 'st_profile_name_main', 'st_profile_suffix',...
    'bl_time', 'bl_display_defparam', 'bl_graph_evf', 'bl_display', 'it_display_every', 'bl_post'});
[bl_profile, st_profile_path, ...
    st_profile_prefix, st_profile_name_main, st_profile_suffix, ...
    bl_time, bl_display_defparam, bl_graph_evf, bl_display, it_display_every, bl_post] = params_group{:};
params_group = values(support_map, {'it_display_summmat_rowmax', 'it_display_summmat_colmax'});
[it_display_summmat_rowmax, it_display_summmat_colmax] = params_group{:};

%% Display Parameters

if (bl_display_defparam)
    fft_container_map_display(param_map);
    fft_container_map_display(support_map);
end

%% Initialize Output Matrixes

mt_val_cur = zeros(length(ar_a_meshk),length(ar_z));
mt_val = mt_val_cur - 1;
mt_pol_a = zeros(length(ar_a_meshk),length(ar_z));
mt_pol_a_cur = mt_pol_a - 1;
mt_pol_k = zeros(length(ar_a_meshk),length(ar_z));
mt_pol_k_cur = mt_pol_k - 1;
mt_pol_idx = zeros(length(ar_a_meshk),length(ar_z));

% We did not need these in ff_oz_vf or ff_oz_vf_vec
% see
% <https://fanwangecon.github.io/M4Econ/support/speed/partupdate/fs_u_c_partrepeat_main.html
% fs_u_c_partrepeat_main> for why store using cells.
cl_u_c_store = cell([it_z_n, 1]);
cl_c_valid_idx = cell([it_z_n, 1]);

%% Initialize Convergence Conditions

bl_vfi_continue = true;
it_iter = 0;
ar_val_diff_norm = zeros([it_maxiter_val, 1]);
ar_pol_diff_norm = zeros([it_maxiter_val, 1]);
mt_pol_perc_change = zeros([it_maxiter_val, it_z_n]);

%% Iterate Value Function
% Loop solution with 4 nested loops
%
% # loop 1: over exogenous states
% # loop 2: over endogenous states
% # loop 3: over choices
% # loop 4: add future utility, integration--loop over future shocks
%

% Start Profile
if (bl_profile)
    close all;
    profile off;
    profile on;
end

% Start Timer
if (bl_time)
    tic;
end

% Value Function Iteration
while bl_vfi_continue
    it_iter = it_iter + 1;
    
    %% Solve Optimization Problem Current Iteration
    
    % loop 1: over exogenous states
    for it_z_i = 1:length(ar_z)
        
        if (it_iter == 1)
            % Consumption
            mt_c = f_cons(mt_coh_wkb(:, it_z_i)', ar_a_meshk, ar_k_mesha);

            % EVAL current utility: N by N, f_util defined earlier
            if (fl_crra == 1)
                mt_utility = f_util_log(mt_c);
                fl_u_neg_c = f_util_log(fl_c_min);            
            else
                mt_utility = f_util_crra(mt_c);
                fl_u_neg_c = f_util_crra(fl_c_min);            
            end

            % Eliminate Complex Numbers
            mt_it_c_valid_idx = (mt_c <= fl_c_min);
            mt_utility(mt_it_c_valid_idx) = fl_u_neg_c;        
            
            % Store in cells
            cl_u_c_store{it_z_i} = mt_utility;            
            cl_c_valid_idx{it_z_i} = mt_it_c_valid_idx;
            
        end
        
        % f(z'|z)
        ar_z_trans_condi = mt_z_trans(it_z_i,:);
        
        % EVAL EV((A',K'),Z'|Z) = V((A',K'),Z') x p(z'|z)', (N by Z) x (Z by 1) = N by 1
        mt_evzp_condi_z = mt_val_cur * ar_z_trans_condi';
        
        % EVAL add on future utility, N by N + N by 1
        mt_utility = cl_u_c_store{it_z_i}  + fl_beta*mt_evzp_condi_z;
        
        % Index update
        % using the method below is much faster than index replace
        % see <https://fanwangecon.github.io/M4Econ/support/speed/index/fs_subscript.html fs_subscript>
        mt_it_c_valid_idx = cl_c_valid_idx{it_z_i};        
        mt_utility = mt_utility.*(~mt_it_c_valid_idx) + fl_u_neg_c*(mt_it_c_valid_idx);

        % Optimization: remember matlab is column major, rows must be
        % choices, columns must be states
        % <https://en.wikipedia.org/wiki/Row-_and_column-major_order COLUMN-MAJOR>  
        [ar_opti_val1_z, ar_opti_idx_z] = max(mt_utility);
        mt_val(:,it_z_i) = ar_opti_val1_z;
        mt_pol_a(:,it_z_i) = ar_a_meshk(ar_opti_idx_z);
        mt_pol_k(:,it_z_i) = ar_k_mesha(ar_opti_idx_z);        
        if (it_iter == (it_maxiter_val + 1))
            mt_pol_idx(:,it_z_i) = ar_opti_idx_z;
        end

    end
    
    %% Check Tolerance and Continuation
    
    % Difference across iterations
    ar_val_diff_norm(it_iter) = norm(mt_val - mt_val_cur);
    ar_pol_diff_norm(it_iter) = norm(mt_pol_a - mt_pol_a_cur) + norm(mt_pol_k - mt_pol_k_cur);
    ar_pol_a_perc_change = sum((mt_pol_a ~= mt_pol_a_cur))/(it_ameshk_n);
    ar_pol_k_perc_change = sum((mt_pol_k ~= mt_pol_k_cur))/(it_ameshk_n);    
    mt_pol_perc_change(it_iter, :) = mean([ar_pol_a_perc_change;ar_pol_k_perc_change]);
    
    % Update
    mt_val_cur = mt_val;
    mt_pol_a_cur = mt_pol_a;
    mt_pol_k_cur = mt_pol_k;
    
    % Print Iteration Results
    if (bl_display && (rem(it_iter, it_display_every)==0))
        fprintf('VAL it_iter:%d, fl_diff:%d, fl_diff_pol:%d\n', ...
            it_iter, ar_val_diff_norm(it_iter), ar_pol_diff_norm(it_iter));
        tb_valpol_iter = array2table([mean(mt_val_cur,1);...
                                      mean(mt_pol_a_cur,1); ...
                                      mean(mt_pol_k_cur,1); ...
                                      mt_val_cur(it_ameshk_n,:); ...
                                      mt_pol_a_cur(it_ameshk_n,:); ...
                                      mt_pol_k_cur(it_ameshk_n,:)]);
        tb_valpol_iter.Properties.VariableNames = strcat('z', string((1:size(mt_val_cur,2))));
        tb_valpol_iter.Properties.RowNames = {'mval', 'map', 'mak', 'Hval', 'Hap', 'Hak'};
        disp('mval = mean(mt_val_cur,1), average value over a')
        disp('map  = mean(mt_pol_a_cur,1), average choice over a')
        disp('mkp  = mean(mt_pol_k_cur,1), average choice over k')
        disp('Hval = mt_val_cur(it_ameshk_n,:), highest a state val')
        disp('Hap = mt_pol_a_cur(it_ameshk_n,:), highest a state choice')
        disp('mak = mt_pol_k_cur(it_ameshk_n,:), highest k state choice')                
        disp(tb_valpol_iter);
    end
    
    % Continuation Conditions:
    % 1. if value function convergence criteria reached
    % 2. if policy function variation over iterations is less than
    % threshold
    if (it_iter == (it_maxiter_val + 1))
        bl_vfi_continue = false;
    elseif ((it_iter == it_maxiter_val) || ...
            (ar_val_diff_norm(it_iter) < fl_tol_val) || ...
            (sum(ar_pol_diff_norm(max(1, it_iter-it_tol_pol_nochange):it_iter)) < fl_tol_pol))
        % Fix to max, run again to save results if needed
        it_iter_last = it_iter;
        it_iter = it_maxiter_val;        
    end
    
end

% End Timer
if (bl_time)
    toc;
end

% End Profile
if (bl_profile)
    profile off
    profile viewer
    st_file_name = [st_profile_prefix st_profile_name_main st_profile_suffix];
    profsave(profile('info'), strcat(st_profile_path, st_file_name));
end

%% Process Optimal Choices

result_map = containers.Map('KeyType','char', 'ValueType','any');
result_map('mt_val') = mt_val;
result_map('mt_pol_idx') = mt_pol_idx;

mt_coh = f_coh(ar_z, ar_a_meshk, ar_k_mesha);
result_map('cl_mt_coh') = {mt_coh, zeros(1)};
result_map('cl_mt_pol_a') = {mt_pol_a, zeros(1)};
result_map('cl_mt_pol_k') = {mt_pol_k, zeros(1)};
result_map('cl_mt_pol_c') = {f_cons(mt_coh, mt_pol_a, mt_pol_k), zeros(1)};
result_map('ar_st_pol_names') = ["cl_mt_coh", "cl_mt_pol_a", "cl_mt_pol_k", "cl_mt_pol_c"];

if (bl_post)
    bl_input_override = true;
    result_map('ar_val_diff_norm') = ar_val_diff_norm(1:it_iter_last);
    result_map('ar_pol_diff_norm') = ar_pol_diff_norm(1:it_iter_last);
    result_map('mt_pol_perc_change') = mt_pol_perc_change(1:it_iter_last, :);
    result_map = ff_akz_vf_post(param_map, support_map, armt_map, func_map, result_map, bl_input_override);
end

%% Display Various Containers

if (bl_display_defparam)

    %% Display 1 support_map
    fft_container_map_display(support_map, it_display_summmat_rowmax, it_display_summmat_colmax);

    %% Display 2 armt_map
    fft_container_map_display(armt_map, it_display_summmat_rowmax, it_display_summmat_colmax);

    %% Display 3 param_map
    fft_container_map_display(param_map, it_display_summmat_rowmax, it_display_summmat_colmax);

    %% Display 4 func_map
    fft_container_map_display(func_map, it_display_summmat_rowmax, it_display_summmat_colmax);

    %% Display 5 result_map
    fft_container_map_display(result_map, it_display_summmat_rowmax, it_display_summmat_colmax);

end

end
