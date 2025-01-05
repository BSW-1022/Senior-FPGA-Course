library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity VGA is
	Port (clock : in std_logic;						    --系統時脈
          reset : in std_logic;						    --初始化按鈕
          color_btn : in std_logic_vector (2 downto 0); --顏色選擇按鈕 100紅色 010綠色 001 藍色
          ledout:out std_logic_vector (3 downto 0);     --顯示顏色選擇按鈕的 1 0 狀況、暫停按紐狀況，使用 LED
		  movement_btn:in std_logic; --暫停移動按鈕
          start_btn:in std_logic;--開始按鈕
          left_borad_up:in std_logic;--左板向上按鈕
          left_borad_down:in std_logic;--左板向下按鈕
          right_borad_up: in std_logic;--右板向上按鈕
          right_borad_down: in std_logic; --右板向下按鈕
          o_red : out std_logic_vector (3 downto 0);    --VGA的 Red訊號
          o_green : out std_logic_vector (3 downto 0);  --VGA的 Green訊號
          o_blue : out std_logic_vector (3 downto 0);   --VGA的 Blue訊號
          o_hs : out std_logic; 						--VGA的水平訊號
          o_vs : out std_logic						    --VGA的垂直訊號
		  );
end VGA;
architecture Behavioral of VGA is
	signal clk_div_cnt:std_logic_vector(26 downto 0):= (others => '0'); --除頻counter
    signal to_vga_clk:std_logic:='0'; --給vga的時脈 
	signal toUpdatePositionClk:std_logic:='0'; --給球的時脈	
    --以下VGA參數
	--水平的參數
    constant C_H_SYNC_PULSE : integer := 96;
    constant C_H_BACK_PORCH : integer := 48;
    constant C_H_ACTIVE_TIME : integer := 640;
    constant C_H_LINE_PERIOD : integer := 800; --整個水平訊號的週期 包含 Front Porch
    --垂直的參數
    constant C_V_SYNC_PULSE : integer := 2;
    constant C_V_BACK_PORCH : integer := 33;
    constant C_V_ACTIVE_TIME : integer := 480;
    constant C_V_FRAME_PERIOD : integer := 525; --整個垂直訊號的週期 包含 Front Porch
    
	--以下圓參數
    signal center_x : integer := ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH); -- 圓心x座標
    signal center_y : integer := ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH); -- 圓心y座標
    constant radius : integer := 10;   -- 圓半徑  
    --以下板子參數
    signal left_rectangle_x : integer := C_H_SYNC_PULSE + C_H_BACK_PORCH+ 20; -- 左板x座標
    signal left_rectangle_y : integer := C_V_SYNC_PULSE + C_V_BACK_PORCH + 240; -- 左板y座標
    signal right_rectangle_x : integer := C_H_SYNC_PULSE + C_H_BACK_PORCH+ 620; -- 右板x座標
    signal right_rectangle_y : integer := C_V_SYNC_PULSE + C_V_BACK_PORCH + 240; -- 右板y座標   
    constant length : integer := 100;   -- 長方形長度
    constant width : integer := 20;   -- 長方形寬度 
    
    signal R_h_cnt : integer := 0;
    signal R_v_cnt : integer := 0;
    signal W_active_flag : STD_LOGIC; --Actice旗號，功能:判斷是否在螢幕範圍內 

	--座標變動的參數
    --圓形
    constant speed_x : integer := 3; -- 水平速度
    constant speed_y : integer := 2; -- 垂直速度          
    --方形
    constant rectan_speed_y : integer := 4; -- 左板垂直速度  
    constant right_rectan_speed_y : integer := 4;  -- 右板垂直速度   
    --以下球的狀態參數
    type state_type is (start,pause,right_and_down_shift,left_and_down_shift,left_and_up_shift,right_and_up_shift);
    signal state: state_type:=start;
	--狀態儲存
    type state_register_type is (nothing,right_and_down_shift,left_and_down_shift,left_and_up_shift,right_and_up_shift);
    signal state_register: state_register_type:=nothing;       
begin
	--除頻處理
    div_clk:process(clock,reset)
    begin
        if reset='1' then
            clk_div_cnt<= (others=>'0');
        elsif clock='1' and clock'event then
            clk_div_cnt <= clk_div_cnt + '1';
        end if;
    end process div_clk;
    to_vga_clk <= clk_div_cnt(1);
	toUpdatePositionClk <= clk_div_cnt(20);

	--水平訊號處理
    horizontal_process:process(to_vga_clk, reset)
    begin
        if reset = '1' then
            R_h_cnt <= 0;
        elsif rising_edge(to_vga_clk) then
            if R_h_cnt = C_H_LINE_PERIOD - 1 then
                R_h_cnt <= 0;
            else
                R_h_cnt <= R_h_cnt + 1;
            end if;
        end if;
    end process horizontal_process;
    o_hs <= '0' when R_h_cnt < C_H_SYNC_PULSE else '1';
    
    --垂直訊號處理
    vertical_process:process(to_vga_clk, reset)
    begin
        if reset = '1' then
            R_v_cnt <= 0;
        elsif rising_edge(to_vga_clk) then
            if R_v_cnt = C_V_FRAME_PERIOD - 1 then
                R_v_cnt <= 0;
            elsif R_h_cnt = C_H_LINE_PERIOD - 1 then
                R_v_cnt <= R_v_cnt + 1;
			else
				null;
            end if;
        end if;
    end process vertical_process;
    o_vs <= '0' when R_v_cnt < C_V_SYNC_PULSE else '1';
    
    W_active_flag <= '1' when (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH) and
                               R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME) and
                               R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH) and
                               R_v_cnt < (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME)) else '0';
							  
	
	--Ball FSM
	ballFSM: process(clock, reset)
	begin
		if reset = '1' then
            state<=start;
        elsif rising_edge(clock) then 
            case state is
				when start =>                             
					--發球按鈕有按下 狀態切為右下 沒有按下保持原位
					if  start_btn = '1' then
                        state <= right_and_down_shift;      
                    else
                        state <= start;                  
                    end if;      
				when pause =>
                        --暫停按鈕有按下保持不動 沒有按下回到原狀態
						if movement_btn = '1' then					
                            state <= pause;                            
                        else
                            case state_register is
                                when right_and_down_shift =>							
                                    state <= right_and_down_shift;
                                when left_and_down_shift =>
                                    state <= left_and_down_shift;
                                when left_and_up_shift =>
                                    state <= left_and_up_shift;
                                when right_and_up_shift =>
                                    state <= right_and_up_shift;                                                                    
                                when others =>
                                    state <= start;        
                            end case;                              
                        end if;                      
                when right_and_down_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停 沒有按下判斷球是否碰到板子、超過螢幕右邊界、碰到下邊界
					if movement_btn = '1' then
                        state <= pause;
                    else
                        --球超過右邊界 狀態回到開始、位置回到中心
						if center_x + radius >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME then
                            state <= start; 
                        --碰到板子做回擊、狀態切到左下
						elsif center_x + radius >= right_rectangle_x and 
							  center_y >= right_rectangle_y and 
							  center_y <= right_rectangle_y + length then                             
                            state <= left_and_down_shift; 
                        --碰到下邊界做反彈、狀態切為右上
						elsif center_y + radius >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then                              
                            state <= right_and_up_shift;                               
                        --以上條件不成立保持右下移動
						else                            
                            null; 
                        end if;
                     end if;
                when left_and_down_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停 沒有按下判斷球是否碰到板子、超過螢幕左邊界、碰到下邊界
					if movement_btn = '1' then
                        state<=pause; 
                    else
                        --球超過左邊界 狀態回到開始、位置回到中心、右邊得分並記錄
						if center_x - radius <= C_H_SYNC_PULSE + C_H_BACK_PORCH  then
                            state <= start;     
                        --碰到下邊界做反彈、狀態切為左上
						elsif center_y + radius >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then
                            state <= left_and_up_shift; 
                        --碰到板子做回擊、狀態切到右下
						elsif center_x - radius <= left_rectangle_x and 
						      center_y >= left_rectangle_y and 
							  center_y <= left_rectangle_y + length then
                            state <= right_and_down_shift;                            
                        --上述條件不成立 保持左下移動
						else 
                            null;  
                        end if;
                    end if;
                when left_and_up_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停 沒有按下判斷球是否碰到板子、超過螢幕左邊界、碰到上邊界
					if movement_btn = '1' then
                        state<=pause; 
                    else
                        --球超過左邊界 狀態回到開始、位置回到中心、右邊得分並記錄
						if center_x - radius <= C_H_SYNC_PULSE + C_H_BACK_PORCH  then
                            state <= start;                                                                    
                        --碰到板子做回擊、狀態切到右上
						elsif center_x - radius <= left_rectangle_x and 
							  center_y >= left_rectangle_y and 
							  center_y <= left_rectangle_y + length then                           
                            state <= right_and_up_shift;                            
                        --碰到上邊界做反彈、狀態切為左下
						elsif center_y - radius <= C_V_SYNC_PULSE + C_V_BACK_PORCH then                            
                            state <= left_and_down_shift;     
                        --保持左上移動
						else                            
                            state<=left_and_up_shift;  
                        end if;
                     end if;
                when right_and_up_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停 沒有按下判斷球是否碰到板子、超過螢幕右邊界、碰到上邊界
					if movement_btn = '1' then
                        state<=pause; 
                    else
                        --球超過右邊界 狀態回到開始、位置回到中心、左邊得分並記錄
						if center_x + radius >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME then
                            state <= start;                                     
                        --碰到上邊界做反彈、狀態切為右下
						elsif center_y - radius <= C_V_SYNC_PULSE + C_V_BACK_PORCH  then
                            state <= right_and_down_shift; 
                        --碰到板子做回擊、狀態切到左上
						elsif center_x + radius >= right_rectangle_x and 
							  center_y >= right_rectangle_y and 
							  center_y <= right_rectangle_y + length then                            
                            state <= left_and_up_shift; 
                        --保持右上移動
						else                             
                            state <= right_and_up_shift;                            
                        end if;
                     end if;                                                               
                when others => 
                    state <= start;                                                                                                     
            end case;
        end if;
	end process ballFSM;
	
	--state Register Process
	stateRegisterProcess: process(clock, reset)
	begin
		if reset = '1' then
            state_register <= nothing;
        elsif rising_edge(clock) then 
            case state is
				when start =>                             
					state_register <= nothing;     
				when pause =>
                    --暫停按鈕有按下保持儲存的狀態 沒有按下回到清空儲存的狀態
					if movement_btn = '1' then						
                        state_register <= state_register;                          
                    else
						state_register <= nothing;                               
                    end if;                         
                when right_and_down_shift =>
					--暫停按鈕有按下移動暫停 狀態切到暫停並把狀態記錄起來
					if movement_btn = '1' then
                        state_register <= right_and_down_shift;
					else
						state_register <= nothing; 
                    end if;
                when left_and_down_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停並把狀態記錄起來
					if movement_btn = '1' then
                        state_register <= left_and_down_shift;
                    else
						state_register <= nothing; 
                    end if;
                when left_and_up_shift =>
                    --暫停按鈕有按下移動暫停 狀態切到暫停並把狀態記錄起來
					if movement_btn = '1' then
                        state_register <= left_and_up_shift;
                    else
						state_register <= nothing; 
                    end if;
                when right_and_up_shift =>
					--暫停按鈕有按下移動暫停 狀態切到暫停並把狀態記錄起來
					if movement_btn = '1' then
                        state_register <= right_and_up_shift;
                    else
						state_register <= nothing; 
                    end if;
                when others => 
					state_register <= nothing;                                                                                                      
            end case;
        end if;
	end process stateRegisterProcess;	
	

	--球位移的處理
    update_circle_position: process(toUpdatePositionClk, reset)
    begin
        --重置時球座標回到中心
		if reset = '1' then
            center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
            center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);
        elsif rising_edge(toUpdatePositionClk) then 
            case state is
				when start =>                             
					--發球按鈕有按下 往右下移動
					if  start_btn = '1' then    
                        center_x <= center_x + speed_x;
                        center_y <= center_y + speed_y;
                    else
                        center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                        center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);                        
                    end if;      
				when pause =>
                        --暫停按鈕有按下保持不動 放開暫停根據狀態暫存器按鈕往原本方向移動
						if movement_btn = '1' then
                            center_x <= center_x;
                            center_y <= center_y;							                            
                        else
                            case state_register is
                                when right_and_down_shift =>
									center_x <= center_x + speed_x;
									center_y <= center_y + speed_y;									
                                when left_and_down_shift =>
									center_x <= center_x - speed_x;
									center_y <= center_y + speed_y;	
                                when left_and_up_shift =>
									center_x <= center_x - speed_x;
									center_y <= center_y - speed_y;	
                                when right_and_up_shift =>
									center_x <= center_x + speed_x;
									center_y <= center_y - speed_y;	                                                                     
                                when others =>
                                    center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
									center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);        
                            end case;                              
                        end if;                      
                when right_and_down_shift =>
                    --暫停按鈕有按下移動暫停 
					if movement_btn = '1' then
                        center_x <= center_x;
                        center_y <= center_y;
                    else
                        --球超過右邊界 位置回到中心
						if center_x + radius >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME then
                            center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                            center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH); 
                        --碰到板子往左下
						elsif center_x + radius >= right_rectangle_x and 
							  center_y >= right_rectangle_y and 
							  center_y <= right_rectangle_y + length then
                            center_x <= center_x - speed_x;
                            center_y <= center_y + speed_y;                              
                        --碰到下邊界往右上
						elsif center_y + radius >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then
                            center_x <= center_x + speed_x;
                            center_y <= center_y - speed_y;                                                            
                        --以上條件不成立保持右下移動
						else                            
                            center_x <= center_x + speed_x;
                            center_y <= center_y + speed_y;  
                        end if;
                     end if;
                when left_and_down_shift =>
                    --暫停按鈕有按下移動暫停 
					if movement_btn = '1' then
                        center_x <= center_x;
                        center_y <= center_y;
                    else
                        --球超過左邊界 位置回到中心
						if center_x - radius <= C_H_SYNC_PULSE + C_H_BACK_PORCH  then
                            center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                            center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);                     
                        --碰到下邊界往左上
						elsif center_y + radius >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then
                            center_x <= center_x - speed_x;
                            center_y <= center_y - speed_y; 
                        --碰到板子往左下
						elsif center_x - radius <= left_rectangle_x and 
						      center_y >= left_rectangle_y and 
							  center_y <= left_rectangle_y + length then
                            center_x <= center_x + speed_x;
                            center_y <= center_y + speed_y;                                                 
                        --上述條件不成立 保持左下移動
						else
                            center_x <= center_x - speed_x;
                            center_y <= center_y + speed_y;  
                        end if;
                    end if;
                when left_and_up_shift =>
                    --暫停按鈕有按下移動暫停 
					if movement_btn = '1' then
                        center_x <= center_x;
                        center_y <= center_y;
                    else
                        --球超過左邊界位置回到中心
						if center_x - radius <= C_H_SYNC_PULSE + C_H_BACK_PORCH  then
                            center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                            center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);                                                                      
                        --碰到板子往右上
						elsif center_x - radius <= left_rectangle_x and 
							  center_y >= left_rectangle_y and 
							  center_y <= left_rectangle_y + length then
                            center_x <= center_x + speed_x;
                            center_y <= center_y - speed_y;                                                        
                        --碰到上邊界往左下
						elsif center_y - radius <= C_V_SYNC_PULSE + C_V_BACK_PORCH then
                            center_x <= center_x - speed_x;
                            center_y <= center_y + speed_y;                                   
                        --保持左上移動
						else                            
                            center_x <= center_x - speed_x;
                            center_y <= center_y - speed_y;   
                        end if;
                     end if;
                when right_and_up_shift =>
                    --暫停按鈕有按下移動暫停 
					if movement_btn = '1' then
                        center_x <= center_x;
                        center_y <= center_y;
                    else
                        --球超過右邊界 位置回到中心、
						if center_x + radius >= C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME then
                            center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                            center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);                                      
                        --碰到上邊界做反彈、狀態切為右下
						elsif center_y - radius <= C_V_SYNC_PULSE + C_V_BACK_PORCH  then
                            center_x <= center_x + speed_x;
                            center_y <= center_y + speed_y; 
                        --碰到板子做回擊、狀態切到左上
						elsif center_x + radius >= right_rectangle_x and 
							  center_y >= right_rectangle_y and 
							  center_y <= right_rectangle_y + length then
                            center_x <= center_x - speed_x;
                            center_y <= center_y - speed_y;                              
                        --保持右上移動
						else
                            center_x <= center_x + speed_x;
                            center_y <= center_y - speed_y;                                                         
                        end if;
                     end if;                                                               
                when others => 
                    center_x <= ( (C_H_ACTIVE_TIME / 2) + C_H_SYNC_PULSE + C_H_BACK_PORCH);
                    center_y <= ( (C_V_ACTIVE_TIME / 2) + C_V_SYNC_PULSE + C_V_BACK_PORCH);                                                                                                       
            end case;
        end if;
    end process update_circle_position;	
	
	-- update left rectangle position
    updateLRP: process(toUpdatePositionClk, reset)
    begin
        if reset = '1' then
            --左方形板子回到原位
            left_rectangle_x <= C_H_SYNC_PULSE + C_H_BACK_PORCH + 20;
            left_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH + 240;            
        elsif rising_edge(toUpdatePositionClk) then 
            --暫停按下不動  
            if movement_btn = '1' then   
				left_rectangle_y <= left_rectangle_y;     
            else
                --判斷左板向上按鈕是否按下  如果按下判斷是否到達螢幕上邊界 如果到達保持原位 沒有則往上移              
                if left_borad_up = '1' then
                    if left_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH then
                        left_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH;
                    else
                        left_rectangle_y <= left_rectangle_y - rectan_speed_y; 
                    end if; 
                 --判斷左板向上下按鈕是否按下  如果按下判斷是否到達螢幕下邊界 如果到達保持原位 沒有則往下移 
                elsif  left_borad_down= '1' then
                    if left_rectangle_y + length  >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then
                         left_rectangle_y <= left_rectangle_y;  
                    else
                         left_rectangle_y <= left_rectangle_y + rectan_speed_y;  
                    end if;
                --都沒有按下保持原位   
                else
                    null; 
                end if;                                                                    
            end if;  
        end if;
	end process updateLRP;
	
	-- update right rectangle position
    updateRRP: process(toUpdatePositionClk, reset)
    begin
        if reset = '1' then
            right_rectangle_x <= C_H_SYNC_PULSE + C_H_BACK_PORCH + 620;
            right_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH + 240;          
        elsif rising_edge(toUpdatePositionClk) then 
            --暫停按下不動  
            if movement_btn = '1' then   
				right_rectangle_y <= right_rectangle_y;     
            else
                --判斷右板向上按鈕是否按下  如果按下判斷是否到達螢幕上邊界 如果到達保持原位 沒有則往上移 
                if right_borad_up = '1' then
                    if right_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH then
                        right_rectangle_y <= C_V_SYNC_PULSE + C_V_BACK_PORCH;
                    else
                        right_rectangle_y <= right_rectangle_y - right_rectan_speed_y; 
                    end if; 
                 --判斷右板向下按鈕是否按下  如果按下判斷是否到達螢幕下邊界 如果到達保持原位 沒有則往下移 
                elsif right_borad_down= '1' then
                    if right_rectangle_y + length  >= C_V_SYNC_PULSE + C_V_BACK_PORCH + C_V_ACTIVE_TIME then
                        right_rectangle_y <= right_rectangle_y;  
                    else
                        right_rectangle_y <= right_rectangle_y + right_rectan_speed_y;  
                    end if; 
                 --都沒有按下保持原位  
                else
                    null;  
                end if;                                                                                     
            end if;    
        end if;
	end process updateRRP;

	--VGA輸出處理
	vga_output:process(to_vga_clk, reset)
	variable point_dist: integer;		--用於計算與圓的距離       
    variable Y_distance: integer;		--用於計算長方形的距離
    begin
        if reset = '1' then
            o_red <= (others => '0');
            o_green <= (others => '0');
            o_blue <= (others => '0');
        elsif rising_edge(to_vga_clk) then
            --判斷是否在螢幕範圍內
			if W_active_flag = '1' then
				-- 計算R_h_cnt及R_v_cnt到圓心的距離
                point_dist := (R_h_cnt - center_x) * (R_h_cnt - center_x) +  (R_v_cnt - center_y) * (R_v_cnt - center_y);                    
                -- 判斷當前 hcnt跟 vcnt與圓心的距離是不是在圓上或圓內，如果有顯示顏色                
                if point_dist <= radius * radius then
                    --像素在圓內根據顏色按鈕可以更換顏色
                    if color_btn(2) = '1' then
                        o_red <= "1111";
                        o_green <= "0000";
                        o_blue <= "1111";
                    elsif color_btn(1) = '1' then
                        o_red <= "1111";
                        o_green <= "1111";
                        o_blue <= "0000";
                    elsif color_btn(0) = '1' then
                        o_red <= "0000";
                        o_green <= "0000";
                        o_blue <= "1111";
                    else
                        o_red <= "1111";
                        o_green <= "0000";
                        o_blue <= "0000";
                    end if;                                
                    -- 當前hcnt跟vcnt構成與圓心的距離不在圓內，不顯示圓形的像素
                    --但如果 hcnt跟vcnt如果在長方形板子顯示範圍內要顯示長方形                
                else
					--判斷是否在左板顯示範圍 
                    if R_h_cnt > C_H_SYNC_PULSE + C_H_BACK_PORCH  and R_h_cnt <= C_H_SYNC_PULSE + C_H_BACK_PORCH + width then
						--計算 vcnt與左板子的 y座標距離 
                        Y_distance := R_v_cnt - left_rectangle_y;      
                        --利用距離判斷是否在板子內 在板子內就顯示
                        if Y_distance >= 0 and Y_distance <= length   then
                            o_red <= "0000";
                            o_green <= "0000";
                            o_blue <= "1111";
                        -- 大於就不顯示
                        else
                            o_red <= "0000";
                            o_green <= "0000";
                            o_blue <= "0000";
                        end if;      
                    --判斷是否在右板顯示範圍                                                                                
                    elsif R_h_cnt>= C_H_SYNC_PULSE + C_H_BACK_PORCH + (C_H_ACTIVE_TIME - width) and 
					      R_h_cnt < C_H_SYNC_PULSE + C_H_BACK_PORCH + C_H_ACTIVE_TIME then
                        --計算 vcnt與右板子的 y座標距離 
                        Y_distance := R_v_cnt-right_rectangle_y;       
                        if Y_distance >= 0 and Y_distance <= length   then
                            o_red <= "0000";
                            o_green <= "0000";
                            o_blue <= "1111";
                        else
                            o_red <= (others => '0');
                            o_green <= (others => '0');
                            o_blue <= (others => '0');
                        end if;                                                
                    else
                        o_red <= "0000";
                        o_green <= "0000";
                        o_blue <= "0000";
                    end if;
                end if;
            else
				--螢幕範圍以外輸出黑色
                o_red <= (others => '0');
                o_green <= (others => '0');
                o_blue <= (others => '0');
            end if;
        end if;            
    end process vga_output;
    ledout(2 downto 0)<=color_btn;
	ledout(3)<=movement_btn;	
end Behavioral;
