%% fig2a.m
% GROWTH PHENOMENA PREDICTION BY THE MODEL
% Figure 2: a

% Parameter fitting results: model predictions for growth rates and ribosomal
% mass fractions in different media and chloramphenicol concs, compared to
% real-life measurement to which the parameters were fitted. Includes
% linear fits illustrating the bacterial growth laws

%% CLEAR parameters, add paths of all files

addpath(genpath('..'))

clear
%close all

%% VECTOR of fitted parameter values

theta=[0.953427, 4165.26, 5992.78, 0.000353953];

%% DEFINE starting parameter values (to compare with the fit)

params = {
    {'a_r/a_a', 1,  0} % metabolic gene transcription rate
    {'nu_max', 6000,  0} % max. tRNA aminoacylatio rate
    {'K_t', 80000, 0} % MM constants for translation elongation and tRNA charging rates
    {'kcm', 0.3594/1000, 0} % chloramphenicol binding rate constant
    };

% record original params into a single vector
theta_origin=zeros([size(params,1) 1]);
for i=1:size(theta_origin,1)
    theta_origin(i) = params{i}{2};
end

%% LOAD Experimental data (to compare with the fit)

% read the experimental dataset (eq2 strain of Scott 2010)
dataset = readmatrix('data/growth_rib_fit_notext.csv');

% nutrient qualities are equally log-spaced points
nutr_quals=logspace(log10(0.08),log10(0.5),6);

% get inputs: nutrient quality and h; get outputs: l and rib mass frac
data.xdata=[]; % initialise inputs array
data.ydata=[]; % intialise outputs array
for i = 1:size(dataset,1)
    if dataset(i,1)>0.3
        % inputs
        nutr_qual = nutr_quals(fix((i-1)/5)+1); % records start from worst nutrient quality
        h = dataset(i,4)*1000; % all h values for same nutr quality same go one after another. Convert to nM from uM!
        data.xdata=[data.xdata; [nutr_qual,h]];
    
        % outputs
        l = dataset(i,1); % growth rate (1/h)
        phi_r = dataset(i,3); % ribosome mass fraction
        data.ydata=[data.ydata; [l,phi_r]];
    end
end

%% SET UP the simulator

sim=cell_simulator; % initialise simulator

% parameters for getting steady state
sim.tf = 10; % single integraton step timeframe
Delta = 0.1; % threshold that determines if we're in steady state
Max_iter = 75; % maximum no. iterations (checking if SS reached over first 750 h)

sim.opt = odeset('reltol',1.e-6,'abstol',1.e-9); % more lenient integration tolerances for speed


%% GET model predictions with fitted parameters
ymodel=scaledaa_modelfun(theta,data.xdata,sim,Delta,Max_iter);

disp(['SOS=',num2str(sum((ymodel-data.ydata).^2))]) % print resultant sum of squared errors

%% COLOURS FOR THE PLOT 

colours={[0.6350 0.0780 0.1840],...
    [0.4660 0.6740 0.1880],...
    [0.4940 0.1840 0.5560],...
    [0.9290 0.6940 0.1250],...
    [0.8500 0.3250 0.0980],...
    [0 0.4470 0.7410]};

%% FIGURE 2 A

Fa = figure('Position',[0 0 385 280]);
set(Fa, 'defaultAxesFontSize', 9)
set(Fa, 'defaultLineLineWidth', 1)

hold on
colourind=1;
last_nutr_qual=data.xdata(1,1);
for i=1:size(data.xdata,1)
    if(data.xdata(i,1)~=last_nutr_qual)
        colourind=colourind+1;
        last_nutr_qual=data.xdata(i,1);
    end
    plot(data.ydata(i,1),data.ydata(i,2),'o','Color',colours{colourind},'LineWidth',1) % real data
    plot(ymodel(i,1),ymodel(i,2),'+','Color',colours{colourind},'MarkerSize',8,'LineWidth',1.25) % model predictions

end
ylabel('\phi_r, ribosomal mass fraction','FontName','Arial');
xlabel('\lambda, growth rate [1/h]','FontName','Arial')
 
%% ADD lines for 1ST GROWTH LAW FITS

% group data by nutrient quality
xs_1={[],[],[],[]};
ys_1={[],[],[],[]};
nutrind=1;
chlorind=1;
last_nutr_qual=data.xdata(1,1);
for i=1:size(data.xdata,1)
    if(data.xdata(i,1)~=last_nutr_qual)
        nutrind=nutrind+1;
        chlorind=1;
        last_nutr_qual=data.xdata(i,1);
    end
    xs_1{chlorind}(end+1)=ymodel(i,1);
    ys_1{chlorind}(end+1)=ymodel(i,2);
    chlorind=chlorind+1;
end

% make linear fits
fit_coeffs=zeros([nutrind 2]);
for chlorind=1:size(xs_1,2)
    if(size(xs_1{chlorind},2)>=2)
        linfit=polyfit(xs_1{chlorind},ys_1{chlorind},1);
        fit_coeffs(chlorind,1)=linfit(1);
        fit_coeffs(chlorind,2)=linfit(2);
    end
end

% plot
dashings={'--','-.',':','none'};
for chlorind=3:(-1):1
    if(fit_coeffs(chlorind,1)~=0)
        xpoints=linspace(0,xs_1{chlorind}(end)*1.1,100); % points for which we plot the linear fit
        ypoints=polyval(fit_coeffs(chlorind,:),xpoints);
        plot(xpoints,ypoints,'Color','k','LineStyle',dashings{chlorind},'LineWidth',0.5)
    end
end

%% ADD lines for 2ND GROWTH LAW FITS

% group data by nutrient quality
xs_2={[]};
ys_2={[]};
nutrind=1;
chlorind=1;
last_nutr_qual=data.xdata(1,1);
for i=1:size(data.xdata,1)
    if(data.xdata(i,1)~=last_nutr_qual)
        nutrind=nutrind+1;
        chlorind=1;
        last_nutr_qual=data.xdata(i,1);
        xs_2{nutrind}=[];
        ys_2{nutrind}=[];
    end
    xs_2{nutrind}(chlorind)=ymodel(i,1);
    ys_2{nutrind}(chlorind)=ymodel(i,2);
    chlorind=chlorind+1;
end

% make linear fits - only based on points with up to 4 uM chloramphenicol
fit_coeffs=zeros([nutrind 2]);
for nutrind=1:size(xs_2,2)
    if(size(xs_2{nutrind},2)==2 || size(xs_2{nutrind},2)==3)
        linfit=polyfit(xs_2{nutrind},ys_2{nutrind},1);
        fit_coeffs(nutrind,1)=linfit(1);
        fit_coeffs(nutrind,2)=linfit(2);
    elseif(size(xs_2{nutrind},2)>3)
        linfit=polyfit(xs_2{nutrind}(1:3),ys_2{nutrind}(1:3),1);
        fit_coeffs(nutrind,1)=linfit(1);
        fit_coeffs(nutrind,2)=linfit(2);
    end
end

% plot
for nutrind=flip(1:size(xs_2,2))
    if(fit_coeffs(nutrind,1)~=0)
        xpoints=linspace(0,xs_2{nutrind}(1)*1.1,100); % points for which we plot the linear fit
        ypoints=polyval(fit_coeffs(nutrind,:),xpoints);
        plot(xpoints,ypoints,'Color',colours{nutrind},'LineWidth',0.5)
    end
end

%% SETTINGS of the plot
xlim([0 1.8])
ylim([0 0.46])

axis square
grid on
box on
hold off

%% FUNCTION for obtaining our cell model's predictions
% Based on dream_modelfun but uses a scaled value of a_a

function ymodel=scaledaa_modelfun(theta,xdata,sim,Delta,Max_iter)
    % reset parameters and initial condition
    sim=sim.set_default_parameters();
    sim=sim.set_default_init_conditions();

    % change fitted parameters to current values
    sim.parameters('a_a') = 3.881e5; % metabolic prot. transcription rate (/h)
    sim.parameters('a_r') = sim.parameters('a_a').*theta(1); % ribosome transcription rate (/h) - rescaled!
    sim.parameters('nu_max') = theta(2); % max metabolic rate (/h)
    sim.parameters('K_e') = theta(3); % elongation rate Hill constant (nM)
    sim.parameters('K_nut') = theta(3); % tRNA charging rate Hill constant (nM)
    sim.parameters('kcm') = theta(4); % chloramphenical binding rate constant (/h/nM)
    
    % find steady state values for every input
    ymodel=zeros([size(xdata,1) 2]); % initialise array of avlues predicted by the model
    for i=1:size(xdata,1)
        %disp(i)
        % change parameter values to relevant inputs
        sim.init_conditions('s')=xdata(i,1);
        sim.init_conditions('h')=xdata(i,2);
        
        % evaluate steady state
        ss=get_steady(sim,Delta,Max_iter); % evaluate steady state value

        % get growth rate and ribosome mass fraction
        par=sim.parameters;
        m_a = ss(1);
        m_r = ss(2);
        p_a = ss(3);
        R = ss(4);
        tc = ss(5);
        tu = ss(6);
        Bcm = ss(7);
        s = ss(8);
        h = ss(9);
        ss_het=ss(10 : (9+2*sim.num_het) ).';
    
        e=sim.form.e(par,tc); % translation elongation rate
        kcmh=par('kcm').*h; % ribosome inactivation rate due to chloramphenicol
    
        % ribosome dissociation constants
        k_a=sim.form.k(e,par('k+_a'),par('k-_a'),par('n_a'),kcmh);
        k_r=sim.form.k(e,par('k+_r'),par('k-_r'),par('n_r'),kcmh);
        k_het=ones(sim.num_het,1);

        % ribosome dissociation constants for heterologous genes
        if(sim.num_het>0)
            for j=1:sim.num_het
                k_het(i)=sim.form.k(e,...
                sim.parameters(['k+_',sim.het.names{j}]),...
                sim.parameters(['k-_',sim.het.names{j}]),...
                sim.parameters(['n_',sim.het.names{j}]),...
                kcmh);
            end
        end
    
        D=1+(m_a./k_a+m_r./k_r+sum(ss_het(1:sim.num_het)./k_het))./...
            (1-par('phi_q')); % denominator in ribosome competition calculations
        B=R.*(1-1./D); % actively translating ribosomes - INCLUDING HOUSEKEEPING GENES
    
        % growth rate
        l=sim.form.l(par,e,B);
        
        % RECORD!
        ymodel(i,1)=l; % record growth rate
        ymodel(i,2)=(R+Bcm).*sim.parameters('n_r')./sim.parameters('M'); % record ribosome mass fraction
    end
end