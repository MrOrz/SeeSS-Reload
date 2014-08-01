# SeeSS-LiveReload

## 研究目的

此研究的目的是觀測和分析網頁開發者在開發網頁時，遇到未預期的 CSS 問題 (glitch) 的狀況。

此 Google Chrome extension 會抓取開發者遇到的問題並回報，回報的圖和文字會上傳到開發者自己的 Google drive；使用者可以選擇刪掉敏感資訊，再分享給研究者。

我們會紀錄的資訊僅限有開啟 LiveReload extension 的分頁內容、螢幕大小與使用者標記，用 MHTML 方式直接存到開發者 Google Drive 上的特定資料夾。除此資料之外，沒有多收取任何資訊。


## 安裝步驟

此程式是以 Chrome extension 取代 livereload extension，所以在開發時不需再開啟 livereload ，直接載入此程式即可。
安裝方式如下，請擇一：

### 方法一、使用封裝的 Chrome Extension（較容易）

請[下載 crx 封裝檔 :inbox_tray:](https://github.com/MrOrz/SeeSS-Reload/raw/master/dist/LiveReload-with-SeeSS-logger.crx) ，並**從資料夾**拖曳進 Google Chrome 視窗，即可安裝。

初次安裝會要求 google drive 權限。


### 方法二、Build from source

1. `git clone git@github.com:MrOrz/SeeSS-Reload.git`

2. Build Chrome Extension
	~~~
	$ cd SeeSS-Reload
	$ npm install -g coffee
	$ npm install
	$ rake build
	~~~ 

3. 打開 Chrome 瀏覽器，瀏覽到 `chrome://extensions/`

4. 點選「載入未封裝功能」、點選 **SeeSS-Reload/Chrome/LiveReload** 資料夾

5. 初次安裝會要求 google drive 權限。

## 使用方式

1. 點下按鈕打開 liverload server，如圖。
	
	![](https://dl.dropboxusercontent.com/u/50022655/fig1.png)

2. 在發現 CSS 問題時，按下 livereload extension 按鈕，跳出 popup 視窗如下圖
	
	![](https://dl.dropboxusercontent.com/u/50022655/fig2.png)

3. 點選放大鏡 **click to inspect element...** 可選取網頁上有問題的 element。

	![](https://dl.dropboxusercontent.com/u/50022655/fig2.5.png)

	接著左上會出現已選取 glitch 的訊息，並請再次打開 popup 。

	![](https://dl.dropboxusercontent.com/u/50022655/fig3.png)

4. 打開 popup 後輸入錯誤描述，並點選 **Store glitch to Google Drive**

	![](https://dl.dropboxusercontent.com/u/50022655/fig4.png)

5. 右上角會出現已經上傳的小跳窗(沒有跳出來請將 extension 關掉 **已啟用** 再重新打開。)

	![](https://dl.dropboxusercontent.com/u/50022655/fig4.5.png)


這樣回報 glitch 就完成囉！

回報的網頁會被存在您自己的 Google Drive 裡頭，這個 Chrome Extension 並_不會_將您開發的網頁傳送到您的 Google Drive 之外的其他地方。那麼，收集到的 glitch 又要如何傳給研究者（@MrOrz）呢？

## 將 Glitch 傳給研究者 @MrOrz

1. 開發一段時間之後可到 Google Drive 的「SeeSS Collected Data」查看已上傳網頁。若想要查看個別 MHT 檔，請下載檔案後用 Google Chrome 打開。

	![](https://dl.dropboxusercontent.com/u/50022655/fig5.png)

2. 點選 share 到開發者信箱: **johnsonliang7[小老鼠]gmail.com** 

	![](https://dl.dropboxusercontent.com/u/50022655/fig6.png)


研究者 @MrOrz 不會將您傳送給研究者的網頁資料傳送給研究專案之外的任何其他第三者。目前 SeeSS 專案只有 @MrOrz 以及指導教授 @profmike ，研究計畫的成員若有更動，會更新於此 README。


## 特殊狀況說明
1. 每隔一個小時會跳出跳窗更新 Google Drive 的 Access Token，無需理會。
	
	![ ](https://dl.dropboxusercontent.com/u/50022655/fig-window.png) 

2. 開發中使用 inspector 除錯時，會使用方式的步驟三會無效，原因是 chrome 不允許兩個以上的 inspector 同時運作，此時可以選擇
	* 關掉開發中的 inpector
	* 在欲選取的 element 中，增加屬性 (**Add ettribute**)：`__SEESS_GLITCH__`
	
	下面的例子是以 p 為例。
	
	![](https://dl.dropboxusercontent.com/u/50022655/fig7.png)
