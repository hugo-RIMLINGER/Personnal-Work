open_system('interpolation_cubique')
modele_workspace = get_param('interpolation_cubique','ModelWorkspace');

%d�claration des variables 

puissance_deux = 512;
bande_passante = 20e6;
interval_pilote = 150; 
nbr_sous_porteuse = fix(puissance_deux*(interval_pilote/(interval_pilote+1)));
size_prefixe_cyclique = 3; 


nbr_zero = puissance_deux - nbr_sous_porteuse-(fix(nbr_sous_porteuse/interval_pilote));
nbr_pilote = fix(nbr_sous_porteuse/interval_pilote);
nbr_total_canaux = nbr_sous_porteuse + nbr_pilote + nbr_zero;


symbol_sample_time = (nbr_total_canaux )/ bande_passante;
binary_sample_time = symbol_sample_time / (nbr_sous_porteuse*2);

%assignation des variables au mod�le simulink 
assignin(modele_workspace,'nbr_sous_porteuse',nbr_sous_porteuse);
assignin(modele_workspace,'size_prefixe_cyclique',size_prefixe_cyclique);
assignin(modele_workspace,'nbr_zero',nbr_zero);
assignin(modele_workspace,'nbr_pilote',nbr_pilote);
assignin(modele_workspace,'nbr_total_canaux',nbr_total_canaux);
assignin(modele_workspace,'bande_passante',bande_passante);
assignin(modele_workspace,'symbol_sample_time',symbol_sample_time);
assignin(modele_workspace,'binary_sample_time',binary_sample_time);



nbr_sous_porteuse = getVariable(modele_workspace,'nbr_sous_porteuse');
bande_passante = getVariable(modele_workspace,'bande_passante');
symbol_sample_time = getVariable(modele_workspace,'symbol_sample_time');
binary_sample_time = getVariable(modele_workspace,'binary_sample_time');

display(binary_sample_time);
display(symbol_sample_time);
display(nbr_sous_porteuse);
display(nbr_total_canaux);
display(1/binary_sample_time);



