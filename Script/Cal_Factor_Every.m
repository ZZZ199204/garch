%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 计算滚动factor 参数结果
% 动态parameters
% 这个是采用动态的parameters，即parameters根据每条数据的前YC年计算而出
% factor个数:numfactors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Factor_Result1,Factor_Result2] = Cal_Factor_Every(data,Var_startIndex,weight1,weight2,name,p,o,q,numfactors,YC)

YC=YC+1;
if isempty(p)
    p=1;
end
if isempty(o)
    o=0;
end
if isempty(q)
    q=1;
end
if isempty(Var_startIndex)
    Var_startIndex=2349;
end

[Var_lens,Var_cols]=size(data); %
k=Var_cols;
if ~isempty(numfactors) && numfactors>k    
    error('numfactors超过维数！');
end
% new data 
newData=[];
newData_F=[];
sigma=[];
[newData,newData_F,sigma] = MakeNewData_F(data);
% save Factor Result
Equity_Factor_PARAMETERS=[];
ht=[];
for i=Var_startIndex:Var_lens
    index=i-Var_startIndex+1; 
    if (i-260-261*YC+1)<1
        subIndex=1;
    else
        subIndex=i-260-261*YC+1;
    end
    mData=newData_F(subIndex:i-260-1,:);
    m_new2=newData(i-260-1-260:i-260-1,:);
    m_new2_F=newData_F(i-260-1-260:i-260-1,:);
    sigma_F=sigma(i-260-1-260:i-260-1,:);
   [PARAMETERS,HT,W,PC]= o_mvgarch(mData,numfactors,p,o,q);
    Equity_Factor_PARAMETERS(:,:,index)=PARAMETERS;
    paraW=[];
    paraA=[];
    paraB=[];
    for i2=1:numfactors;
        paraW(i2)=PARAMETERS((i2-1)*3+1);
        paraA(i2)=PARAMETERS((i2-1)*3+2);
        paraB(i2)=PARAMETERS((i2-1)*3+3);
    end
    paraW=paraW';
    paraA=paraA';
    paraB=paraB';
   
    [w, pc] = pca(m_new2_F,'outer');	
   errors=[];
   for t=1:261
    F = pc(t,1:numfactors);
    weights = bsxfun(@times,w(:,1:numfactors),sigma_F(t,:)');
    
    erros=bsxfun(@minus,m_new2(t,:)',weights*F');
    errors(t,:)=erros';
   end
    H_omega=cov(errors);
    omega=diag(H_omega,0);   
    omega=diag(omega);
   
    Ht=cov(F);
    ht=diag(Ht,0);
    
    ft=F(end,:,:);
    ft=ft';
    
    htsub1=bsxfun(@times,paraA,ft.^2);

    htsub2=bsxfun(@times,paraB,ht);

    ht1=bsxfun(@plus,paraW,htsub1);
 
    ht1=bsxfun(@plus,ht1,htsub2);
    Ht1=diag(ht1);
    w_F=bsxfun(@times,w(:,1:numfactors),sigma_F(end,:)');

    H_Factor=w_F * Ht1 * w_F' + omega;     
    Factor_Result1(index)=sqrt(weight1'*H_Factor*weight1);
    if ~isempty(weight2)
        Factor_Result2(index)=sqrt(weight2'*H_Factor*weight2);
    end
end 
% save Factor Result 
save(strcat('../modelResults/',name,'_Factor',num2str(p),num2str(o),num2str(q),'_PARAMETERS'),'Equity_Factor_PARAMETERS');
% 保存数据文件
if ~isempty(weight2)
    save(strcat('../Result/',name,'_Factor',num2str(p),num2str(o),num2str(q),'_Every_',num2str(YC),'_Defensive'),'Factor_Result1');
    save(strcat('../Result/',name,'_Factor',num2str(p),num2str(o),num2str(q),'_Every_',num2str(YC),'_Offensive'),'Factor_Result2');   
else
    save(strcat('../Result/',name,'_Factor',num2str(p),num2str(o),num2str(q),'_Every_',num2str(YC)),'Factor_Result1');
end



