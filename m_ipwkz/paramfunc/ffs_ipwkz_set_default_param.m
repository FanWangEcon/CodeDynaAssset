%% Set Model Parameters (Interpolated + Percentage + Risky + Safe Asset + Save + Borrow)
% *back to <https://fanwangecon.github.io Fan>'s
% <https://fanwangecon.github.io/CodeDynaAsset/ Dynamic Assets Repository>
% Table of Content.*

%%
function [param_map, support_map] = ffs_ipwkz_set_default_param(varargin)
%% FFS_IPKZ_SET_DEFAULT_PARAM setting model default parameters
% Define model parameters, similar to
% <https://fanwangecon.github.io/CodeDynaAsset/m_akz/paramfunc/html/ffs_akz_set_default_param.html
% ffs_akz_set_default_param> see that file for descriptions.
%
% Several changes here: 1, inclusion of percentage based choice grids
%
% @param it_subset integer default parameter control subsetting. it_subset = 1 is
% basic invoke quick test. it_subset = 2 is main invoke. it_subset = 3 is
% profiling invoke. it_subset = 4 is matlab publish.
%
% @param bl_display_defparam boolean local printing
%
% @return param_map container parameters needed for solving the model
%
% @return support_map container programming control parameters like to graph to print etc
%
% @example
%
%   it_param_set = 1;
%   [param_map, support_map] = ffs_akz_set_default_param(it_param_set);
%
% @seealso
%
% * <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbz/paramfunc/html/ffs_ipwkbz_set_default_param.html ffs_ipwkbz_set_default_param>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_ipwkbzr/paramfunc/html/ffs_ipwkbzr_set_default_param.html ffs_ipwkbzr_set_default_param>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_fibs/m_ipwkbz_paramfunc/html/ffs_ipwkbz_fibs_set_default_param.html ffs_ipwkbz_fibs_set_default_param>
% * <https://fanwangecon.github.io/CodeDynaAsset/m_fibs/m_ipwkbzr_paramfunc/html/ffs_ipwkbzr_fibs_set_default_param.html ffs_ipwkbzr_fibs_set_default_param>
%

%% Default

it_subset = 4;
if (isempty(varargin))
    bl_display_defparam = true;
else
    bl_display_defparam = false;
end
default_params = {it_subset bl_display_defparam};
[default_params{1:length(varargin)}] = varargin{:};
[it_subset, bl_display_defparam] = default_params{:};

%% Setting param_map container

param_map = containers.Map('KeyType','char', 'ValueType','any');

% model name
param_map('st_model') = 'ipwkz';

% Preferences
param_map('fl_crra') = 1.5;
param_map('fl_beta') = 0.94;
param_map('fl_nan_replace') = -9999;

%% 1b. Production Function Parameters

% CD Production Function Parameters
param_map('fl_Amean') = 1;
param_map('fl_alpha') = 0.36;
param_map('fl_delta') = 0.08;

%% 2a. Set Borrowing Control Parameters

% Borrowing Parameters
param_map('fl_b_bd') = 0; % borrow bound, = 0 if save only

% Minimum Consumption, utility lower bound. The cmin parameter and
% fl_nan_replace parameter have no effects on value function, just for
% resetting invalid choice grid values. fl_nan_replace reset invalid k
% choice given w. fl_c_min resets invalid consumption levels due to w
% choices that are invalid. But this is the case when fl_w > 0.
param_map('fl_c_min') = 0.02;

%% 2b. Set Asset Grid Parameters

% Asset Grids
% Toal savings aggregate grid (see discussion on top). 35 points picked for
% for this problem w_max is overall for everyone, but each individual coh
% levle has associated w_max. Unlike before, when we had it_w_n, now we
% have it_w_perc_n which is how many percentage grid points to have. We
% also now include fl_w_interp_grid_gap, the grip gap for interpolation.
param_map('fl_w_min') = param_map('fl_b_bd'); % but b_bd overrides this
param_map('fl_w_max') = 50;
param_map('it_w_perc_n') = 50;

% Risky Capital Asset Vector
% see graph below for how it looks graphically
% in principle keep it_k_n the same as it_w_n to have equi-distance points
% in triangle choice grid. For the ipwkz this k_max is the overall max, not
% the individual max given coh. we have it_ak_perc_n rather than it_ak_n
% for percentage.
param_map('fl_k_min') = 0;
param_map('fl_k_max') = (param_map('fl_w_max') - param_map('fl_b_bd'));
param_map('it_ak_perc_n') = param_map('it_w_perc_n'); % grid for a and k the same

% Prices
% shock is on k, not on labor, fl_w is fixed wage income
param_map('fl_w') = 1.28*0.3466; % min(z*w) from benchmark az model

%% 2c. Set Asset Interpolation Parameters

% Interpolation
% fl_coh_interp_grid_gap controls the number of coh points at which to solve the model
% it_c_interp_grid_gap determines the gap between consumption terpolation
% points. For consumption interpolation 10^-4 is extremely accurate, there
% should be no perceptible differences in value and policy functions when the
% it_c_interp_grid_gap <= 0.001 compared to actual evaluation. Also include
% now fl_w_interp_grid_gap above, which is for interpolation over w.
param_map('fl_coh_interp_grid_gap') = 0.1;

% param_map('it_coh_interp_n') = 500;
param_map('it_c_interp_grid_gap') = 10^-4;

% Interpolation gap second stage w
% previously only it_w_n, now two grids control w it_w_perc_n for 2nd stage
% fl_w_interp_grid_gap for first stage, make them the same length for
% default.
param_map('fl_w_interp_grid_gap') = 0.1;
% param_map('fl_w_interp_grid_gap') = (param_map('fl_w_max') - param_map('fl_w_min'))/param_map('it_w_perc_n');

%% 3. Set Interest Rates non-Shock Parameters
% Prices
% shock is on k, not on labor, fl_w is fixed wage income

param_map('fl_w') = 1.28*0.3466; % min(z*w) from benchmark az model
param_map('fl_r_save') = 0.025;
param_map('fl_r_borr') = 0.095;

%% 4. Set Shock 2 Productivity Shock Parameters

% Production Function
% Productivity Shock Parameters
param_map('it_z_n') = 15;
param_map('fl_z_mu') = 0;
param_map('fl_z_rho') = 0.8;
param_map('fl_z_sig') = 0.2;

%% 5. Set Solution Control Parameters
% Solution Accuracy
param_map('it_maxiter_val') = 250;
param_map('it_maxiter_dist') = 1000;
param_map('st_analytical_stationary_type') = 'eigenvector'; % could be loop or vector
param_map('fl_tol_val') = 10^-5;
param_map('fl_tol_pol') = 10^-5;
param_map('fl_tol_dist') = 10^-5;
param_map('it_tol_pol_nochange') = 25; % number of iterations where policy does not change

%% Setting support_map container

support_map = containers.Map('KeyType','char', 'ValueType','any');

% root directory
[st_root_path] = preamble(false);
st_matimg_path_root = [st_root_path '/m_ipwkz/'];
support_map('st_matimg_path_root') = st_matimg_path_root;

% timer
support_map('bl_time') = true;

% Print Controls
support_map('bl_display') = true;
support_map('bl_display_dist') = false;
support_map('it_display_every') = 5; % how often to print results

% Profile Controls
support_map('bl_profile') = false;
support_map('bl_profile_dist') = false; % distribution profile
support_map('st_profile_path') = [st_matimg_path_root '/solve/profile/'];
support_map('st_profile_prefix') = [''];
support_map('st_profile_name_main') = ['_default'];
support_map('st_profile_suffix') = ['_p' num2str(it_subset)];

support_map('bl_post') = false;

% Final Print
support_map('bl_display_final') = false; % print finalized results
support_map('bl_display_final_dist') = false; % print finalized results
support_map('bl_display_final_dist_detail') = false;
support_map('it_display_final_rowmax') = 100; % max row to print (states/iters)
support_map('it_display_final_colmax') = 12; % max col to print (shocks)
it_display_summmat_rowmax = 7;
it_display_summmat_colmax = 7;
support_map('it_display_summmat_rowmax') = it_display_summmat_rowmax;
support_map('it_display_summmat_colmax') = it_display_summmat_colmax;

% Mat File Controls
support_map('bl_mat') = false;
support_map('st_mat_path') = [st_matimg_path_root '/solve/mat/'];
support_map('st_mat_prefix') = [''];
support_map('st_mat_name_main') = ['_default'];
support_map('st_mat_suffix') = ['_p' num2str(it_subset)];

% Graphing Controls
support_map('bl_graph') = false;
support_map('bl_graph_onebyones') = true;
support_map('bl_graph_val') = true;
support_map('bl_graph_pol_lvl') = true;
support_map('bl_graph_pol_pct') = true;
support_map('bl_graph_coh_t_coh') = true;

% Image Saving Controls (given graphing)
support_map('st_title_prefix') = '';
support_map('bl_img_save') = false;
support_map('st_img_path') = [st_matimg_path_root '/solve/img/'];
support_map('st_img_prefix') = [''];
support_map('st_img_name_main') = ['_default'];
support_map('st_img_suffix') = ['_p' num2str(it_subset) '.png'];
support_map('st_mat_test_path') = [st_matimg_path_root '/test/ff_ipwkz_ds_vecsv/mat/'];

% Sub-function graphing controls
support_map('bl_graph_funcgrids') = false;
support_map('bl_graph_funcgrids_detail') = false;
support_map('bl_display_funcgrids') = false;
support_map('bl_graph_evf') = false;
support_map('bl_display_evf') = false;
support_map('bl_display_defparam') = false;

%% Subset Options
%
% # it_subset = 1 is basic invoke quick test
% # it_subset = 2 is main invoke
% # it_subset = 3 is profiling invoke
% # it_subset = 4 is matlab publish.
%

% close figures
close all;

if (ismember(it_subset, [3]))
    % Profile run
    support_map('bl_profile') = true;
    support_map('bl_display') = false; % don't print
    support_map('bl_time') = true;

elseif (ismember(it_subset, [1,2,4]))

    % Main Run
    support_map('bl_time') = true;
    support_map('bl_display_defparam') = true;
    support_map('bl_display') = true;
    support_map('it_display_every') = 5;

    support_map('bl_post') = true;
    support_map('bl_display_final') = true;
    support_map('bl_mat') = false;
    support_map('bl_graph') = true;
    support_map('bl_graph_onebyones') = false;
    support_map('bl_img_save') = true;

    if (ismember(it_subset, [1]))
        % TEST quick
        param_map('it_w_perc_n') = 20;
        param_map('it_ak_perc_n') = param_map('it_w_perc_n');
        param_map('it_z_n') = 5;

        param_map('fl_coh_interp_grid_gap') = 0.25;
        param_map('it_c_interp_grid_gap') = 0.001;
        param_map('fl_w_interp_grid_gap') = 1;

        param_map('it_maxiter_val') = 50;
        param_map('it_tol_pol_nochange') = 1000;
        support_map('bl_display') = true;
        support_map('it_display_every') = 1;

        support_map('bl_graph') = false;
    end

    if (ismember(it_subset, [4]))
        support_map('bl_time') = false;
        support_map('bl_display') = false;
        support_map('bl_graph_onebyones') = true;
        support_map('bl_img_save') = false;
    end

end


%% Subset Options for Distribution solutions
%
% # it_subset = 5 is basic invoke quick test
% # it_subset = 6 is invoke full test
% # it_subset = 7 is profiling invoke
% # it_subset = 8 is matlab publish
% # it_subset = 9 is invoke operational (only final stats) and coh graph
%

if (ismember(it_subset, [7]))
    % Profile run
    support_map('bl_profile_dist') = true;
    support_map('bl_display') = false; % don't print
    support_map('bl_display_dist') = false; % don't print
    support_map('bl_time') = true;

elseif (ismember(it_subset, [5,6,8,9]))
    % close all
    close all;

    % Main Run
    support_map('bl_time') = true;
    support_map('bl_display_defparam') = true;
    support_map('bl_display') = true;
    support_map('bl_display_dist') = true;
    support_map('it_display_every') = 20;

    support_map('bl_post') = true;
    support_map('bl_display_final_dist') = true;
    support_map('bl_mat') = false;
    support_map('bl_graph') = true;
    support_map('bl_graph_onebyones') = false;
    support_map('bl_img_save') = true;

    % do not generate all graphs when solving for distribution
    support_map('bl_graph_val') = false;
    support_map('bl_graph_pol_lvl') = false;
    support_map('bl_graph_pol_pct') = false;
    support_map('bl_graph_coh_t_coh') = true;

    if (ismember(it_subset, [5]))
        % TEST quick (need to enough to have distribution)
        param_map('it_w_perc_n') = 40;
        param_map('it_ak_perc_n') = param_map('it_w_perc_n');
        param_map('it_z_n') = 5;

        param_map('fl_coh_interp_grid_gap') = 0.25;
        param_map('it_c_interp_grid_gap') = 0.001;
        param_map('fl_w_interp_grid_gap') = 1;

        param_map('it_maxiter_val') = 50;
        param_map('it_tol_pol_nochange') = 1000;
        support_map('bl_display') = true;
        support_map('it_display_every') = 1;

        support_map('bl_display_dist') = true;
        support_map('bl_graph') = false;
    end

    if (ismember(it_subset, [8, 9]))

        support_map('bl_display') = false;
        support_map('bl_display_dist') = false;
        support_map('bl_display_final_dist_detail') = true;
        support_map('bl_graph_onebyones') = true;
        support_map('bl_img_save') = false;

        if (ismember(it_subset, [9]))
            % quietly turn off all graphs, only tables
            support_map('bl_display_defparam') = false;
            support_map('bl_display_final_dist_detail') = false;
            support_map('bl_graph_coh_t_coh') = false;
            support_map('bl_graph') = false;
        end
    end
end

%% Display

if (bl_display_defparam)
    fft_container_map_display(param_map, it_display_summmat_rowmax, it_display_summmat_colmax);
    fft_container_map_display(support_map, it_display_summmat_rowmax, it_display_summmat_colmax);
end

end
