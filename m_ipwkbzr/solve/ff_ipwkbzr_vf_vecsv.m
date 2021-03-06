%% Risky + Safe Asset (Save + Borr + R Shock) Interpolated-Percentage (Optimized-Vectorized)
% *back to <https://fanwangecon.github.io Fan>'s
% <https://fanwangecon.github.io/CodeDynaAsset/ Dynamic Assets Repository>
% Table of Content.*

%%
function result_map = ff_ipwkbzr_vf_vecsv(varargin)
%% FF_IPWKBZR_VF_VECSV solve infinite horizon exo shock + endo asset problem
% This program solves the infinite horizon dynamic savings and risky
% capital asset problem with some ar1 shock. This is the two step solution
% with interpolation and with percentage asset grids version of
% <https://fanwangecon.github.io/CodeDynaAsset/m_akz/solve/html/ff_iwkz_vf_vecsv.html
% ff_iwkz_vf_vecsv>. See that file for more descriptions.
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
% * mt_pol_a matrix states_n by shock_n matrix of converged policy function grid
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
% @include
%
% * <https://github.com/FanWangEcon/CodeDynaAsset/blob/master/m_ipwkbzr/paramfunc/ff_ipwkbzr_evf.m ff_ipwkbzr_evf>
% * <https://github.com/FanWangEcon/CodeDynaAsset/blob/master/m_ipwkbzr/paramfunc/ffs_ipwkbzr_set_default_param.m ffs_ipwkbzr_set_default_param>
% * <https://github.com/FanWangEcon/CodeDynaAsset/blob/master/m_ipwkbzr/paramfunc/ffs_ipwkbzr_get_funcgrid.m ffs_ipwkbzr_get_funcgrid>
% * <https://github.com/FanWangEcon/CodeDynaAsset/blob/master/m_akz/solvepost/ff_akz_vf_post.m ff_akz_vf_post>
%

%% Default
% * it_param_set = 1: quick test
% * it_param_set = 2: benchmark run
% * it_param_set = 3: benchmark profile
% * it_param_set = 4: press publish button

it_param_set = 4;
[param_map, support_map] = ffs_ipwkbzr_set_default_param(it_param_set);

% parameters can be set inside ffs_ipwkbzr_set_default_param or updated here
% param_map('it_w_perc_n') = 50;
% param_map('it_ak_perc_n') = param_map('it_w_perc_n');
% param_map('fl_coh_interp_grid_gap') = 0.025;
% param_map('it_c_interp_grid_gap') = 0.001;
% param_map('fl_w_interp_grid_gap') = 0.25;
% param_map('it_w_perc_n') = 100;
% param_map('it_ak_perc_n') = param_map('it_w_perc_n');
% param_map('fl_z_r_borr_n') = 5;
% param_map('it_z_wage_n') = 15;
% param_map('it_z_n') = param_map('it_z_wage_n') * param_map('fl_z_r_borr_n');
% param_map('fl_coh_interp_grid_gap') = 0.1;
% param_map('it_c_interp_grid_gap') = 10^-4;
% param_map('fl_w_interp_grid_gap') = 0.1;

st_param_which = 'default';

if (ismember(st_param_which, ['default']))

    % default

elseif (ismember(st_param_which, ['small']))

    param_map('it_w_perc_n') = 20;
    param_map('it_ak_perc_n') = param_map('it_w_perc_n');
    param_map('it_z_wage_n') = 4;
    param_map('fl_z_r_borr_n') = 4;
    param_map('it_z_n') = param_map('it_z_wage_n') * param_map('fl_z_r_borr_n');

elseif ismember(st_param_which, ['ff_ipwkbz_vf_vecsv'])

    % ff_ipwkbzr_evf default
    param_map('fl_z_r_borr_min') = 0.095;
    param_map('fl_z_r_borr_max') = 0.095;
    param_map('fl_z_r_borr_n') = 1;

    param_map('fl_r_save') = 0.025;

    param_map('it_z_n') = param_map('it_z_wage_n') * param_map('fl_z_r_borr_n');

end

% get armt and func map
[armt_map, func_map] = ffs_ipwkbzr_get_funcgrid(param_map, support_map); % 1 for override
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
    bl_input_override = true;
    [armt_map, func_map] = ffs_ipwkbzr_get_funcgrid(param_map, support_map);
else
    % Override all
    armt_map = [armt_map; default_params{3}];
    func_map = [func_map; default_params{4}];
end

% append function name
st_func_name = 'ff_ipwkbzr_vf_vecsv';
support_map('st_profile_name_main') = [st_func_name support_map('st_profile_name_main')];
support_map('st_mat_name_main') = [st_func_name support_map('st_mat_name_main')];
support_map('st_img_name_main') = [st_func_name support_map('st_img_name_main')];

%% Parse Parameters 2, Asset Arrays
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid
%
% # ar_interp_c_grid: 1 by I^c, 1st stage consumption interpolation
% # ar_interp_coh_grid: 1 by I^{coh}, 1st stage value function V(coh,z)
% # ar_w_perc: 1 by P^{W=k+b}, 1st stage w \in {w_perc(coh)} choice set
% # ar_w_level: 1 by I^{W=k+b}, 2nd stage k*(w,z) w grid
% # ar_ak_perc: 1 by P^{k and b}, 2nd stage k \in {ask_perc(w,z)} set
%

params_group = values(armt_map, {...
    'ar_interp_c_grid', 'ar_interp_coh_grid', ...
    'ar_w_perc', 'ar_w_level', 'ar_ak_perc'});
[ar_interp_c_grid, ar_interp_coh_grid, ...
    ar_w_perc, ar_w_level, ar_ak_perc] = params_group{:};

%% Parse Parameters 2, interp_coh related matrixes
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. These are grids for 1st stage solution
%
% # mt_interp_coh_grid_mesh_z_wage: I^{coh} by M^w
% # mt_z_wage_mesh_interp_coh_grid: I^{coh} by M^w
% # mt_interp_coh_grid_mesh_w_perc: I^{coh} by P^{LAM=k+b}
% # mt_w_perc_mesh_interp_coh_grid: I^{coh} by P^{LAM=k+b}
%

params_group = values(armt_map, {...
    'mt_interp_coh_grid_mesh_z_wage', ...
    'mt_interp_coh_grid_mesh_w_perc', ...
    'mt_z_wage_mesh_interp_coh_grid', ...
    'mt_w_perc_mesh_interp_coh_grid', ...
    'mt_interp_coh_grid_mesh_z', 'mt_z_mesh_interp_coh_grid', ...
    'cl_mt_coh_wkb_mesh_z_r_borr', 'mt_z_mesh_coh_wkb_seg'});
[mt_interp_coh_grid_mesh_z_wage, ...
    mt_interp_coh_grid_mesh_w_perc, ...
    mt_z_wage_mesh_interp_coh_grid, ...
    mt_w_perc_mesh_interp_coh_grid, ...
    mt_interp_coh_grid_mesh_z, mt_z_mesh_interp_coh_grid, ...
    cl_mt_coh_wkb_mesh_z_r_borr, mt_z_mesh_coh_wkb_seg] = params_group{:};

%% Parse Parameters 3, reachable cash-on-hand
% Dimensions of Various Grids: I for level grid, M for shock grid, P for
% percent grid. These are grids for 1st stage solution
%
% # mt_coh_wkb: (I^k x I^w x M^r) by (M^z)
% # mt_z_wage_mesh_coh_wkb: (I^k x I^w x M^r) by (M^z)
%

params_group = values(armt_map, {...
    'mt_coh_wkb', 'mt_coh_wkb_mesh_z_r_borr', 'mt_z_mesh_coh_wkb', 'mt_z_wage_mesh_coh_wkb'});
[mt_coh_wkb, mt_coh_wkb_mesh_z_r_borr, mt_z_mesh_coh_wkb, mt_z_wage_mesh_coh_wkb] = params_group{:};

%% Parse Parameters 4, other asset arrays

params_group = values(armt_map, {'ar_a_meshk', 'ar_k_mesha'});
[ar_a_meshk, ar_k_mesha] = params_group{:};

%% Parse Parameters 5, Others

% func_map
params_group = values(func_map, {'f_util_log', 'f_util_crra', 'f_cons'});
[f_util_log, f_util_crra, f_cons] = params_group{:};

% param_map
params_group = values(param_map, {'fl_crra', 'fl_beta', ...
    'fl_nan_replace', 'fl_c_min', 'bl_default', 'fl_default_wprime'});
[fl_crra, fl_beta, fl_nan_replace, fl_c_min, bl_default, fl_default_wprime] = params_group{:};
params_group = values(param_map, {'it_maxiter_val', 'fl_tol_val', 'fl_tol_pol', 'it_tol_pol_nochange'});
[it_maxiter_val, fl_tol_val, fl_tol_pol, it_tol_pol_nochange] = params_group{:};
params_group = values(param_map, {'it_z_n', 'fl_z_r_borr_n', 'it_z_wage_n'});
[it_z_n, fl_z_r_borr_n, it_z_wage_n] = params_group{:};
params_group = values(param_map, {'st_v_coh_z_interp_method'});
[st_v_coh_z_interp_method] = params_group{:};

% support_map
params_group = values(support_map, {'bl_profile', 'st_profile_path', ...
    'st_profile_prefix', 'st_profile_name_main', 'st_profile_suffix',...
    'bl_time', 'bl_display_defparam', 'bl_graph_evf', 'bl_display', 'it_display_every', 'bl_post'});
[bl_profile, st_profile_path, ...
    st_profile_prefix, st_profile_name_main, st_profile_suffix, ...
    bl_time, bl_display_defparam, bl_graph_evf, bl_display, it_display_every, bl_post] = params_group{:};
params_group = values(support_map, {'it_display_summmat_rowmax', 'it_display_summmat_colmax'});
[it_display_summmat_rowmax, it_display_summmat_colmax] = params_group{:};

%% Initialize Output Matrixes

mt_val_cur = zeros(length(ar_interp_coh_grid),it_z_n);
mt_val = mt_val_cur - 1;
mt_pol_a = zeros(length(ar_interp_coh_grid),it_z_n);
mt_pol_a_cur = mt_pol_a - 1;
mt_pol_k = zeros(length(ar_interp_coh_grid),it_z_n);
mt_pol_k_cur = mt_pol_k - 1;
mt_pol_idx = zeros(length(ar_interp_coh_grid),it_z_n);

% We did not need these in ff_oz_vf or ff_oz_vf_vec
% see
% <https://fanwangecon.github.io/M4Econ/support/speed/partupdate/fs_u_c_partrepeat_main.html
% fs_u_c_partrepeat_main> for why store using cells.
cl_u_c_store = cell([it_z_n, 1]);
cl_c_valid_idx = cell([it_z_n, 1]);
cl_w_kstar_interp_z = cell([it_z_n, 1]);
for it_z_i = 1:it_z_n
    cl_w_kstar_interp_z{it_z_i} = zeros([length(ar_w_perc), length(ar_interp_coh_grid)]) - 1;
end

clmt_val_wkb_interpolated = cell([fl_z_r_borr_n, 1]);

%% Initialize Convergence Conditions

bl_vfi_continue = true;
it_iter = 0;
ar_val_diff_norm = zeros([it_maxiter_val, 1]);
ar_pol_diff_norm = zeros([it_maxiter_val, 1]);
mt_pol_perc_change = zeros([it_maxiter_val, it_z_n]);

%% Pre-calculate u(c)
% Interpolation, see
% <https://fanwangecon.github.io/M4Econ/support/speed/partupdate/fs_u_c_partrepeat_main.html
% fs_u_c_partrepeat_main> for why interpolate over u(c)

% Evaluate
if (fl_crra == 1)
    ar_interp_u_of_c_grid = f_util_log(ar_interp_c_grid);
    fl_u_cmin = f_util_log(fl_c_min);
else
    ar_interp_u_of_c_grid = f_util_crra(ar_interp_c_grid);
    fl_u_cmin = f_util_crra(fl_c_min);
end
ar_interp_u_of_c_grid(ar_interp_c_grid <= fl_c_min) = fl_u_cmin;

% Get Interpolant
f_grid_interpolant_spln = griddedInterpolant(ar_interp_c_grid, ar_interp_u_of_c_grid, 'spline', 'nearest');

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

    %% Interpolate V(coh, Z) 1: Splinterp2
    % Interpolate reacahble V(coh(k'(w),b'(w),zr,zw'),zw',zr')) given v(coh, z)

    if (strcmp(st_v_coh_z_interp_method, 'method_idx_a'))
        for it_z_r_borr_ctr = 1:1:fl_z_r_borr_n
            clmt_val_wkb_interpolated{it_z_r_borr_ctr} = ...
                splinterp2(mt_val_cur,mt_z_mesh_coh_wkb_seg,cl_mt_coh_wkb_mesh_z_r_borr{it_z_r_borr_ctr});
        end
    end

    %% Interpolate V(coh, Z) 2: griddedInterpolant(V)
    % Interpolate reacahble V(coh(k'(w),b'(w),zr,zw'),zw',zr')) given v(coh, z)

    if (strcmp(st_v_coh_z_interp_method, 'method_idx_b'))
        % Generate Interpolant for v(coh,z)
        % mt_z_wage_mesh_interp_coh_grid is: (I^{coh_interp}) by (M^z)
        f_grid_interpolant_value = griddedInterpolant(mt_val_cur', 'linear', 'nearest');
        for it_z_r_borr_ctr = 1:1:fl_z_r_borr_n
            clmt_val_wkb_interpolated{it_z_r_borr_ctr} = ...
                f_grid_interpolant_value(mt_z_mesh_coh_wkb_seg,...
                                         cl_mt_coh_wkb_mesh_z_r_borr{it_z_r_borr_ctr});
        end
    end

    %% Interpolate V(coh, Z) 3: Store in Cell
    % Interpolate reacahble V(coh(k'(w),b'(w),zr,zw'),zw',zr')) given v(coh, z)

    if (strcmp(st_v_coh_z_interp_method, 'method_cell'))
        f_grid_interpolant_value = griddedInterpolant(...
            mt_z_mesh_interp_coh_grid', mt_interp_coh_grid_mesh_z', ...
            mt_val_cur', 'linear', 'nearest');

        for it_z_r_borr_ctr = 1:1:fl_z_r_borr_n

            clmt_val_wkb_interpolated{it_z_r_borr_ctr} = ...
                f_grid_interpolant_value(mt_z_mesh_coh_wkb_seg,...
                                         cl_mt_coh_wkb_mesh_z_r_borr{it_z_r_borr_ctr});
        end
    end


    %% Interpolate V(coh, Z) 4: Single Call Full Matrix
    % Interpolate reacahble V(coh(k'(w),b'(w),zr,zw'),zw',zr')) given v(coh, z)

    if (strcmp(st_v_coh_z_interp_method, 'method_matrix'))
        % Generate Interpolant for v(coh,z)
        % mt_z_wage_mesh_interp_coh_grid is: (I^{coh_interp}) by (M^z)
        f_grid_interpolant_value = griddedInterpolant(...
            mt_z_mesh_interp_coh_grid', mt_interp_coh_grid_mesh_z', ...
            mt_val_cur', 'linear', 'nearest');

        % Interpolate V(coh(k',b',z',r),z',r') for a specific r'
        % mt_z_wage_mesh_coh_wkb and mt_coh_wkb are: (I^k x I^w x M^r) by (M^z)
        clmt_val_wkb_interpolated = f_grid_interpolant_value(mt_z_mesh_coh_wkb, mt_coh_wkb_mesh_z_r_borr);
    end

    %% Interpolate V(coh, Z) 5: Matrix Store
    % Interpolate reacahble V(coh(k'(w),b'(w),zr,zw'),zw',zr')) given v(coh, z)

    if (strcmp(st_v_coh_z_interp_method, 'method_mat_seg'))

        % 1. Number of W/B/K Choice Combinations
        it_ak_perc_n = length(ar_ak_perc);
        it_w_interp_n = length(ar_w_level);
        it_wak_n = it_w_interp_n*it_ak_perc_n;

        % 2. Initialize V(coh(k'(w),b'(w),zr,zw'),zw',zr'))
        % mt_val_wkb_interpolated is: (I^k x I^w x M^r) by (M^z x M^r)
        % reachable cash-on-hand (as rows) and shocks next period given choices
        % and shocks next period.
        clmt_val_wkb_interpolated = zeros([it_wak_n*fl_z_r_borr_n, it_z_n]);

        % 3. Loop over possible shocks over interest rate
        for it_z_r_borr_ctr = 1:1:fl_z_r_borr_n

            % 4. Interpolate V(coh(k',b',z',r),z',r') for a specific r'
            % v(coh,z) solved on ar_interp_coh_grid, ar_z grids, see
            % ffs_ipwkbzr_get_funcgrid.m. Generate interpolant based on that, Then
            % interpolate for the coh reachable levels given the k(w,z) percentage
            % choice grids in the second stage of the problem.
            %
            % Note mt_val_cur/mt_val dimension is based on interpolant
            % cash-on-hand for rows, and meshed shocks for columns. The meshed
            % shock structure, see
            % <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_get_funcgrid.html
            % ffs_ipwkbzr_get_funcgrid> for details on how the shock grids are
            % formed.

            % Get current z_r_borr from mt_val
            it_mt_val_col_start = it_z_wage_n*(it_z_r_borr_ctr-1) + 1;
            it_mt_val_col_end   = it_mt_val_col_start + it_z_wage_n - 1;
            mt_val_cur_rcolseg =  mt_val_cur(:, it_mt_val_col_start:it_mt_val_col_end);

            % Generate Interpolant for v(coh,z)
            % mt_z_wage_mesh_interp_coh_grid is: (I^{coh_interp}) by (M^z)
            f_grid_interpolant_value = griddedInterpolant(...
                mt_z_wage_mesh_interp_coh_grid', mt_interp_coh_grid_mesh_z_wage', ...
                mt_val_cur_rcolseg', 'linear', 'nearest');

            % Interpolate V(coh(k',b',z',r),z',r') for a specific r'
            % mt_z_wage_mesh_coh_wkb and mt_coh_wkb are: (I^k x I^w x M^r) by (M^z)
            mt_val_wkb_interpolated_seg = f_grid_interpolant_value(mt_z_wage_mesh_coh_wkb, mt_coh_wkb);
            clmt_val_wkb_interpolated(:, it_mt_val_col_start:it_mt_val_col_end) = mt_val_wkb_interpolated_seg;

        end
    end

    %% Solve Second Stage Problem k*(w,z)
    % This is the key difference between this function and
    % <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_set_functions.html
    % ffs_akz_set_functions> which solves the two stages jointly
    % Interpolation first, because solution coh grid is not the same as all
    % points reachable by k and b choices given w.
    support_map('bl_graph_evf') = false;
    if (it_iter == (it_maxiter_val + 1))
        support_map('bl_graph_evf') = bl_graph_evf;
    end
    bl_input_override = true;
    [mt_ev_condi_z_max, ~, mt_ev_condi_z_max_kp, ~] = ...
        ff_ipwkbzr_evf(clmt_val_wkb_interpolated, param_map, support_map, armt_map, bl_input_override);

    %% Solve First Stage Problem w*(z) given k*(w,z)

    % loop 1: over exogenous states
    for it_z_i = 1:it_z_n

        %% A. Interpolate FULL to get k*(w_perc, z), b*(k,w) based on k*(w_level, z)
        % Generate interpolant for (2) k*(ar_w_perc) from k*(ar_w_level,z)
        % There are two w=k'+b' arrays. ar_w_level is the level even grid based
        % on which we solve the 2nd stage problem in ff_ipwkbzr_evf.m. Here for
        % each coh level, we have a different vector of w levels, but the same
        % vector of percentage ws. So we need to interpolate to get the optimal
        % k* and b* choices at each percentage level of w.
        f_interpolante_w_level_kstar_z = griddedInterpolant(ar_w_level, mt_ev_condi_z_max_kp(:, it_z_i)', 'linear', 'nearest');

        % Interpolate (2), shift from w_level to w_perc
        mt_w_kstar_interp_z = f_interpolante_w_level_kstar_z(mt_w_perc_mesh_interp_coh_grid);
        mt_w_astar_interp_z = mt_w_perc_mesh_interp_coh_grid - mt_w_kstar_interp_z;

        % changes in w_perc kstar choices
        mt_w_kstar_diff_idx = (cl_w_kstar_interp_z{it_z_i} ~= mt_w_kstar_interp_z);

        %% B. Calculate UPDATE u(c): u(c(coh_level, w_perc)) given k*_interp, b*_interp
        % Note that compared to
        % <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_set_functions.html
        % ffs_akz_set_functions> the mt_c here is much smaller the same
        % number of columns (states) as in the ffs_akz_set_functions file,
        % but the number of rows equal to ar_w length.
        ar_c = f_cons(mt_interp_coh_grid_mesh_w_perc(mt_w_kstar_diff_idx), ...
            mt_w_astar_interp_z(mt_w_kstar_diff_idx), ...
            mt_w_kstar_interp_z(mt_w_kstar_diff_idx));

        ar_it_c_valid_idx = (ar_c <= fl_c_min);
        % EVAL current utility: N by N, f_util defined earlier
        ar_utility_update = f_grid_interpolant_spln(ar_c);

        % Update Storage
        if (it_iter == 1)
            cl_u_c_store{it_z_i} = reshape(ar_utility_update, [length(ar_w_perc), length(ar_interp_coh_grid)]);
            cl_c_valid_idx{it_z_i} = reshape(ar_it_c_valid_idx, [length(ar_w_perc), length(ar_interp_coh_grid)]);
        else
            cl_u_c_store{it_z_i}(mt_w_kstar_diff_idx) = ar_utility_update;
            cl_c_valid_idx{it_z_i}(mt_w_kstar_diff_idx) = ar_it_c_valid_idx;
        end
        cl_w_kstar_interp_z{it_z_i} = mt_w_kstar_interp_z;

        %% C. Interpolate FULL EV(k*(coh_level, w_perc, z), w - b*|z) based on EV(k*(w_level, z))
        % Generate Interpolant for (3) EV(k*(ar_w_perc),Z)
        f_interpolante_ev_condi_z_max_z = griddedInterpolant(ar_w_level, mt_ev_condi_z_max(:, it_z_i)', 'linear', 'nearest');
        % Interpolate (3), EVAL add on future utility, N by N + N by N
        mt_ev_condi_z_max_interp_z = f_interpolante_ev_condi_z_max_z(mt_w_perc_mesh_interp_coh_grid);

        %% D. Compute FULL U(coh_level, w_perc, z) over all w_perc
        mt_utility = cl_u_c_store{it_z_i} + fl_beta*mt_ev_condi_z_max_interp_z;

        % Index update
        % using the method below is much faster than index replace
        % see <https://fanwangecon.github.io/M4Econ/support/speed/index/fs_subscript.html fs_subscript>
        mt_it_c_valid_idx = cl_c_valid_idx{it_z_i};
        % Default or Not Utility Handling
        if (bl_default)
            % if default: only today u(cmin), transition out next period, debt wiped out
            fl_v_default = fl_u_cmin + fl_beta*f_interpolante_ev_condi_z_max_z(fl_default_wprime);
            mt_utility = mt_utility.*(~mt_it_c_valid_idx) + fl_v_default*(mt_it_c_valid_idx);
        else
            % if default is not allowed: v = u(cmin)
            mt_utility = mt_utility.*(~mt_it_c_valid_idx) + fl_nan_replace*(mt_it_c_valid_idx);
        end

        % percentage algorithm does not have invalid (check to make sure
        % min percent is not 0 in ffs_ipwkbzr_get_funcgrid.m)
        % mt_utility = mt_utility.*(~mt_it_c_valid_idx) + fl_u_neg_c*(mt_it_c_valid_idx);

        %% E. Optimize Over Choices: max_{w_perc} U(coh_level, w_perc, z)
        % Optimization: remember matlab is column major, rows must be
        % choices, columns must be states
        % <https://en.wikipedia.org/wiki/Row-_and_column-major_order COLUMN-MAJOR>
        [ar_opti_val_z, ar_opti_idx_z] = max(mt_utility);

        % Generate Linear Opti Index
        [it_choies_n, it_states_n] = size(mt_utility);
        ar_add_grid = linspace(0, it_choies_n*(it_states_n-1), it_states_n);
        ar_opti_linear_idx_z = ar_opti_idx_z + ar_add_grid;

        ar_opti_aprime_z = mt_w_astar_interp_z(ar_opti_linear_idx_z);
        ar_opti_kprime_z = mt_w_kstar_interp_z(ar_opti_linear_idx_z);
        ar_opti_c_z = f_cons(ar_interp_coh_grid, ar_opti_aprime_z, ar_opti_kprime_z);

        % Handle Default is optimal or not
        if (bl_default)
            % if defaulting is optimal choice, at these states, not required
            % to default, non-default possible, but default could be optimal
            fl_default_opti_kprime = f_interpolante_w_level_kstar_z(fl_default_wprime);
            ar_opti_aprime_z(ar_opti_c_z <= fl_c_min) = fl_default_wprime - fl_default_opti_kprime;
            ar_opti_kprime_z(ar_opti_c_z <= fl_c_min) = fl_default_opti_kprime;
        else
            % if default is not allowed, then next period same state as now
            % this is absorbing state, this is the limiting case, single
            % state space point, lowest a and lowest shock has this.
            ar_opti_aprime_z(ar_opti_c_z <= fl_c_min) = min(ar_a_meshk);
            ar_opti_kprime_z(ar_opti_c_z <= fl_c_min) = min(ar_k_mesha);
        end

        %% F. Store Results
        mt_val(:,it_z_i) = ar_opti_val_z;
        mt_pol_a(:,it_z_i) = ar_opti_aprime_z;
        mt_pol_k(:,it_z_i) = ar_opti_kprime_z;
        if (it_iter == (it_maxiter_val + 1))
            mt_pol_idx(:,it_z_i) = ar_opti_linear_idx_z;
        end

    end

    %% Check Tolerance and Continuation

    % Difference across iterations
    ar_val_diff_norm(it_iter) = norm(mt_val - mt_val_cur);
    ar_pol_diff_norm(it_iter) = norm(mt_pol_a - mt_pol_a_cur) + norm(mt_pol_k - mt_pol_k_cur);
    ar_pol_a_perc_change = sum((mt_pol_a ~= mt_pol_a_cur))/(length(ar_interp_coh_grid));
    ar_pol_k_perc_change = sum((mt_pol_k ~= mt_pol_k_cur))/(length(ar_interp_coh_grid));
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
            mt_val_cur(length(ar_interp_coh_grid),:); ...
            mt_pol_a_cur(length(ar_interp_coh_grid),:); ...
            mt_pol_k_cur(length(ar_interp_coh_grid),:)]);
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

result_map('cl_mt_coh') = {mt_interp_coh_grid_mesh_z, zeros(1)};
result_map('cl_mt_pol_a') = {mt_pol_a, zeros(1)};
result_map('cl_mt_pol_k') = {mt_pol_k, zeros(1)};
mt_pol_c = f_cons(mt_interp_coh_grid_mesh_z, mt_pol_a, mt_pol_k);
mt_pol_c(mt_pol_c <= fl_c_min) = fl_c_min;
result_map('cl_mt_pol_c') = {mt_pol_c, zeros(1)};
result_map('cl_mt_val') = {mt_val, zeros(1)};
result_map('ar_st_pol_names') = ["cl_mt_val", "cl_mt_coh", "cl_mt_pol_a", "cl_mt_pol_k", "cl_mt_pol_c"];

if (bl_post)
    bl_input_override = true;
    result_map('ar_val_diff_norm') = ar_val_diff_norm(1:it_iter_last);
    result_map('ar_pol_diff_norm') = ar_pol_diff_norm(1:it_iter_last);
    result_map('mt_pol_perc_change') = mt_pol_perc_change(1:it_iter_last, :);

    armt_map('mt_coh_wkb_ori') = mt_coh_wkb;
    armt_map('ar_a_meshk_ori') = ar_a_meshk;
    armt_map('ar_k_mesha_ori') = ar_k_mesha;

    % graphing based on coh_wkb, but that does not match optimal choice
    % matrixes for graphs.
    armt_map('mt_coh_wkb') = mt_interp_coh_grid_mesh_z;
    armt_map('it_ameshk_n') = length(ar_interp_coh_grid);
    armt_map('ar_a_meshk') = mt_interp_coh_grid_mesh_z(:,1);
    armt_map('ar_k_mesha') = zeros(size(mt_interp_coh_grid_mesh_z(:,1)) + 0);

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
