% Answers the design question of what kind of material will be the most
% cost effective and efficient for a solar cooker.
function solar_cooker()
% Models the internal energy of the surface of a pot and the water inside
% of it over time, heated from the sun's solar energy.
    insolation = 5; %kWh/m^2/day
    radius_cooker = 2;
    depth_cooker = 0.5;
    A_cooker = pi * radius_cooker / 6 / depth_cooker^2 * ...
        ((radius_cooker^2 + 4 * depth_cooker^2)^(3/2) - ...
        radius_cooker^3); % m^2
    k = 150; % W/m/K average of cast iron conductivity
    radius_pot = 0.134; %m inner radius where water is at
    height_water = 2 / 3 * radius_pot; %m
    height_pot = 0.3; %m
    density_pot = 1300; % kg / m^3
    d = 0.01; %m thickness of the pot walls
    mass_pot = pi * (radius_pot + d)^2 * height_pot * density_pot;
    c_pot = 500; % J / (kg * K)
    % assuming the pot is a cylinder, short and stout with the lid on
    SA_pot_in = 2 * pi * radius_pot * height_pot + 2 * pi * radius_pot^2;
    SA_pot_out = 2 * pi * (radius_pot + d) * height_pot...
        + 2 * pi * (radius_pot + d)^2;
    mass_water = pi * radius_pot^2 * height_water; %density is 1 kg/m^3
    c_water = 4186; % J /(kg * K)
    Tenv = 273 + 30; % K
    Twater = 273 + 10; % CHANGE LATA
    Tpot = 273 + 10;
    e = 0.97; % reflection efficiency %%CAN MODIFY TO TAKE INTO ACCOUNT
    % DIFFERENT COOKER SHAPES
    Tboil = 100 + 273; %K
    
    emmisivity = 0.65; % of cast iron
    sigma = 5.67e-8; %w/m^2/K Stephen Boltzmann's constnat
     
    function res = change_U_system(t, internal_energies)
        % Params: internal energy of pot, internal energy of water
        temp_pot = internal_energies(1) / mass_pot / c_pot;
        temp_water = internal_energies(2) / mass_water / c_water;
        % Assume that the surface area of the cooker is 1 m^2
        % 1 - emmisivity percent of the radiated energy is reflected from
        % the pot. Therefore, only a certain percentage, corresponding to
        % emmisivity is actually absorbed into the pot and available for us
        % of conduction and convection and then radiation outward
        Qsolar = insolation / 24 / 3600 * A_cooker * 3.6e6;  % J
        radiation = Qsolar * e * emmisivity;
        % convection depends on the outside surface area in contact with the
        % environment
        % WILL IGNORE CONVECTION FOR NOW
        % convection = h * SA_pot_out * (Tenv - temp_pot);
        % conduction depends on the surface area of pot touching the inside
        conduction = k * SA_pot_in / d * (temp_pot - temp_water)...
             * (temp_water < 373);
%          fprintf('Water temp: %d\nConduction amount: %d\n\n', temp_water,...
%              conduction)
        % whatever energy is absorbed into the pot is also emmitted through
        % radiation outwards
        emmission = emmisivity * sigma * SA_pot_out * (temp_pot^4 - Tenv^4);
        res = [radiation - conduction - emmission; ...
            conduction];
    end

    function res = get_time_to_boil(reflection_efficiency, cooker_SA)
        A_cooker = cooker_SA;
        e = reflection_efficiency;
        
        % Make event that will stop ode45 when the water boils
        [t, u, TE, UE] = ode23(@change_U_system, [0, 6000], [Tpot * mass_pot * c_pot, ...
        Twater * mass_water * c_water], options);
        res = TE;
        if isempty(TE)
            res = -1;
        end
        
       
    end

    options = odeset('Events', @is_boiling);    
    % Set trigger to go off when the water reaches boiling
    function [value, isterminal, direction] = is_boiling(t, internal_energies)
           %disp(internal_energies(2) / mass_water / c_water)
           % When value = 0, event is triggered
           value = internal_energies(2) - Tboil * mass_water * c_water;
           isterminal = 1; % stop function as soon as this event is reached
           direction = 0; % At any zero (when value = 0) consider this event, not 
                          % only when the function is either increasing (1) or 
                          % decreasing (-1)
    end

    function model(params)
        % Vary the parameters: different cooker SA, reflectivity, pot
        % thickness, water height, radius of pot    
        A_cooker = params(1);
        e = params(2);
        d = params(3);
        radius_pot = params(4);
        height_water = 2 / 3 * radius_pot; %m
        mass_pot = pi * (radius_pot + d)^2 * height_pot * density_pot;
        % assuming the pot is a cylinder, short and stout with the lid on
        SA_pot_in = 2 * pi * radius_pot * height_pot + 2 * pi * radius_pot^2;
        SA_pot_out = 2 * pi * (radius_pot + d) * height_pot...
        + 2 * pi * (radius_pot + d)^2;
        mass_water = pi * radius_pot^2 * height_water; %density is 1 kg/m^3

        fig = params(5); % figure to plot the relationships on
        
        hold on
        [time, internal_energies] = ode23(@change_U_system, [0, 6000], ...
            [Tpot * mass_pot * c_pot, ...
        Twater * mass_water * c_water], options);
        % Plot temperature of water vs time
        figure(2 * fig - 1)
        plot(time / 60, internal_energies(:, 2) / mass_water / c_water - 273)
        
%         hold on
%         % Plot temperature of POT vs time
%         figure(2 * fig)
%         plot(time / 60, internal_energies(:, 1) / mass_pot / c_pot - 273)
    end

    function validation()
       % For validation, produce a couple of graphs:
       SA = [1, 3, 5]; % m^2
       E = [0.65, 0.8, 0.97];
%        D = [0.01, 0.03, 0.07];
%        R = [0.3, 0.5, 0.7];
       SA_orig = 3;
       e_orig = 0.97;
       d_orig = 0.01;
       radius_pot_orig = 0.134;
       % 1) vary the SA of the cooker for constant other things
       for sa = SA
          model([sa, e_orig, d_orig, radius_pot_orig, 1]) 
       end
       
       % 2) vary the reflectivity constant
       for ee = E
           model([SA_orig, ee, d_orig, radius_pot_orig, 2])
       end
       
%        % 3) vary the thickness of the pot
%        for dd = D
%            model([SA_orig, e_orig, dd, radius_pot_orig, 3])
%        end
%        
%        % 4) vary the radius of pot
%        for r = R
%            model([SA_orig, e_orig, d_orig, r, 4])
%        end
    end
    
    % Main function that solar_cooker will run
    function main()
       validation() 
    end

    main()

end