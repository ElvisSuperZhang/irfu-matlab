function corrSOffset(cp,cl_id)
%corrSOffset correct the Sunward offset and amplitude factor
% do a manual correction of the offsets by comparison with 
% CIS and EDI data (must be loaded)
%
% $Id$
%

% Copyright 2004 Yuri Khotyaintsev (yuri@irfu.se)

old_pwd = pwd;
cd(cp.sp) %enter the storage directory

if exist('./mEDSI.mat','file')
	eval(av_ssub('load mEDSI diE?p1234 diEs?p34;',cl_id))
	if exist(av_ssub('diE?p1234',cl_id),'var')
		eval(av_ssub('diE=diE?p1234;',cl_id))
	else
		error('caa:noData','no diE{cl_id}p1234 data in mEDSI')
	end
	if exist(av_ssub('diEs?p34',cl_id),'var')
		eval(av_ssub('load mEDSI D?p12p34; Del=D?p12p34;',cl_id))
		if isreal(Del) 
			eval(av_ssub('diEs=diEs?p34;',cl_id))
		else
			disp('correcting p34')
			Del = imag(Del);
			eval(av_ssub('diEs=diEs?p34-ones(length(diEs?p34),1)*Del;',cl_id))
		end
	else
		error('caa:noData','no diEs{cl_id}p34 data in mEDSI')
	end
else
	cd(old_pwd)
	error('caa:noSuchFile','no mEDSI file')
end

var_list = 'diE_tmp,diEs_tmp';
var_list1 = 'diEp1234,diEsp34';

% load CIS
var = {'diVCEp', 'diVCEh'};
if exist('./mCIS.mat','file')
	CIS=load('mCIS');
	for i=1:length(var)
		eval(av_ssub(['if isfield(CIS,''' var{i} '?''); ' var{i} '=CIS.' var{i} '?; end; clear ' var{i} '?'], cl_id));
	end
	clear CIS
end
if ~exist('diVCEp','var') | ~exist('diVCEh','var') 
	warning('caa:noData','no CIS data loaded')
else
	for i=1:length(var)
		if exist(var{i},'var') 
			var_list = [var_list ',' var{i}];
			var_list1 = [var_list1 ',' var{i}];
		end	
	end
end
clear var

% load EDI
if exist('./mEDI.mat','file')
	EDI=load('mEDI');
	var = 'diEDI';
	eval(av_ssub(['if isfield(EDI,''' var '?''); ' var '=EDI.' var '?; end; clear ' var '?'], cl_id));
	clear EDI
end
if ~exist('diEDI','var') 
	warning('caa:noData','no EDI data loaded')
else
	var_list = [var_list ',diEDI'];
	var_list1 = [var_list1 ',diEDI'];
end

offset = [0 1];
diE_tmp = diE;
diE_tmp(:,2) = diE_tmp(:,2) - offset(1);
diE_tmp(:,2:3) = diE_tmp(:,2:3)*offset(2);
diEs_tmp = diEs;
diEs_tmp(:,2) = diEs_tmp(:,2) - offset(1);
diEs_tmp(:,2:3) = diEs_tmp(:,2:3)*offset(2);

figure(17)
clf
t = tokenize(var_list1,',');
leg = ['''' t{1} ''''];
for i=2:length(t), leg = [leg ',''' t{i} '''']; end
eval(['plotExy(' var_list ')'])
title(sprintf('Cluster %d : offset %.2f [mV/m], amplitude factor %.2f',cl_id,offset(1),offset(2)))
eval(['legend(' leg ')'])

q='0';
while(q ~= 'q')
	q=av_q('Give Ex offset [mV/m] and amplitude factor (s-save,q-quit)[%]>','',num2str(offset,'%.2f '));
	switch(q)
	case 's'
		disp(sprintf('Ddsi%d, Damp%d -> ./mEDSI.mat',cl_id,cl_id))
		eval(av_ssub('Ddsi?=offset(1); Damp?=offset(2);save -append mEDSI Ddsi? Damp?',cl_id))
	case 'q'
		cd(old_pwd)
		return
	otherwise
		[o_tmp,ok] = str2num(q);
		if ok
			if length(o_tmp) > 1
				offset = o_tmp(1:2);
			else
				offset(1) = o_tmp(1);
			end	
			diE_tmp = diE;
			diE_tmp(:,2) = diE_tmp(:,2) - offset(1);
			diE_tmp(:,2:3) = diE_tmp(:,2:3)*offset(2);
			diEs_tmp = diEs;
			diEs_tmp(:,2) = diEs_tmp(:,2) - offset(1);
			diEs_tmp(:,2:3) = diEs_tmp(:,2:3)*offset(2);
			figure(17)
			clf
			eval(['plotExy(' var_list ')'])
			title(sprintf('Cluster %d : offset %.2f [mV/m], amplitude factor %.2f',cl_id,offset(1),offset(2)))
			eval(['legend(' leg ')'])
		else
			disp('invalid command')
		end
	end
end
