package handler

import (
	"embed"
	"io/fs"
	"net/http"
	"strings"
)

//go:embed static/xterm/*
var staticFiles embed.FS

// staticFileHandler 返回一个处理嵌入式静态文件的HTTP处理器
// 正确设置MIME类型，避免text/plain问题
func staticFileHandler() http.Handler {
	// 从embed.FS中提取static子目录
	subFS, err := fs.Sub(staticFiles, "static")
	if err != nil {
		// fallback: 直接使用根目录
		subFS = staticFiles
	}

	fileServer := http.FileServer(http.FS(subFS))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 移除 /static/ 前缀，让FileServer在正确的子目录中查找文件
		r.URL.Path = strings.TrimPrefix(r.URL.Path, "/static/")
		if r.URL.Path == "" {
			r.URL.Path = "xterm/xterm.js"
		}

		// 根据文件扩展名设置正确的MIME类型
		switch {
		case strings.HasSuffix(r.URL.Path, ".js"):
			w.Header().Set("Content-Type", "application/javascript; charset=utf-8")
		case strings.HasSuffix(r.URL.Path, ".css"):
			w.Header().Set("Content-Type", "text/css; charset=utf-8")
		case strings.HasSuffix(r.URL.Path, ".woff2"):
			w.Header().Set("Content-Type", "font/woff2")
		case strings.HasSuffix(r.URL.Path, ".woff"):
			w.Header().Set("Content-Type", "font/woff")
		case strings.HasSuffix(r.URL.Path, ".ttf"):
			w.Header().Set("Content-Type", "font/ttf")
		default:
			w.Header().Set("Content-Type", "application/octet-stream")
		}

		// 设置缓存头
		w.Header().Set("Cache-Control", "public, max-age=86400")

		// 使用修改后的路径提供文件
		fileServer.ServeHTTP(w, r)
	})
}
