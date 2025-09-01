% EAN-13条形码的识别（高发展，2025年9月1日）
%% 提取数据并预处理
filename = "data1.txt";
data = readmatrix(filename);
pixel = data(:,1);
intensity = data(:,2);
average_intensity = mean(intensity);                                        % 求出所有像元的光强平均值
threshold = average_intensity;                                              % 上述平均值作为判断0-1的阈值
%% 显示前置信息
fprintf("\n对于\'%s\'文件数据的解码结果如下：\n",filename);
%% 分别识别有效信号的开始和结束，并将原数字信号只截取有效片段
% 识别信号的开始
for i = 500:2700 % 【适当调整循环开始位置】
    if intensity(i) < threshold
        start_index = i;                                                    % 有效信号开始坐标
        break;
    end
end
% 识别信号的结束
for i = 2500:-1:1 %【适当调整循环结束位置】
    if intensity(i) < threshold
        end_index = i;                                                      % 有效信号结束坐标
        break;
    end
end
effective_intensity = intensity(start_index:end_index,1);                   % 截取有效片段
%% 计算有效像元总数和单模块像元个数（共95个模块）
num_of_effective_pixels = length(effective_intensity);                         % 有效像元数个数 
num_pixels_per_module =  num_of_effective_pixels/95;                        % 计算单个模块对应的像元个数（非整数）
%% 采样求平均，得到每个模块的光强，并转化为每个模块的数字信号
start_index_module = 1;                                                     % 在有效片段中每个模块的开始坐标，初始化
end_index_module = num_pixels_per_module;                                   % 结束坐标，初始化
result_intensity = zeros(95,1);                                             % 各模块对应光强，初始化为零向量

% 从每个模块最中间开始，向左右只取模块像元数的1/4，用这1/2的数据再做平均以确定最终该模块对应的字符
for i = 1:95
    mid_index_module = (start_index_module+end_index_module)/2;             % 在有效片段中每个模块像素的中间坐标
    start_index_sample = round(mid_index_module - num_pixels_per_module/4); % 在有效片段中单个模块采样像元的开始坐标
    end_index_sample = round(mid_index_module + num_pixels_per_module/4);   % 结束坐标
    result_intensity(i) = mean(effective_intensity(start_index_sample:end_index_sample));
    % 更新模块开始和结束坐标
    start_index_module = start_index_module + num_pixels_per_module;
    end_index_module = end_index_module + num_pixels_per_module;
end

new_threshold = mean(result_intensity);                                     % 采用有效片段光强均值作为新阈值

% 光强信号数字化
result_digits = zeros(95,1);                                                % 各模块对应的数字信号，初始化为零向量
for i = 1:95
    if result_intensity(i) > new_threshold
        result_digits(i) = 0;                                               % 注意大于均值定义为0
    else
        result_digits(i) = 1;
    end
end
%% 校验开始符101
if result_digits(1:3) == [1 0 1]'
    fprintf('\n\t【SUCCESS】开始符101位置正确！\n');
else
    fprintf('\n\t【ERROR】开始符101位置有误！\n');
end
%% 校验间隔符01010
if result_digits(46:50) == [0 1 0 1 0]'
    fprintf('\n\t【SUCCESS】间隔符01010位置正确！\n');
else
    fprintf('\n\t【ERROR】间隔符01010位置有误！\n');
end
%% 校验终止符101
if result_digits(93:95) == [1 0 1]'
    fprintf('\n\t【SUCCESS】终止符101位置正确！\n');
else
    fprintf('\n\t【ERROR】终止符101位置有误！\n');
end
%% 对其余字符按照字符表解码（采用decoder函数）
j = 1;
code = -ones(12,1);
% 左侧数据符
for i = 4 : 7: 45
    code(j) = decoder(result_digits(i:i+6));
    j = j + 1;
end
% 右侧数据符 及 校验符
for i = 51 : 7: 92
    code(j) = decoder(result_digits(i:i+6));
    j = j + 1;
end
%% 显示解码结果
code_str = '';
for i = 1 : 12
    ch = num2str(code(i));
    code_str = strcat(code_str,ch);
end
fprintf("\n\t最终解码结果：6 %s\n",code_str);