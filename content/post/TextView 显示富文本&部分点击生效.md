---
title: "TextView 显示富文本&部分点击生效"
description: "本文主要 TextView 显示富文本&部分点击生效"
keywords: "Android,富文本"

date: 2021-03-22T19:47:00+08:00

categories:
  - Android
tags:
  - Android
  - 富文本

url: post/6A8E8E3AD581427DB99794A1680C7F57.html
toc: true
---

本文主要 TextView 显示富文本&部分点击生效。

<!--More-->

最近需求中有个功能，需要实现以下效果：

- 一行白色文本后，跟随一个蓝色的文本。这个蓝色文本可以响应点击操作，白色文本不响应点击操作。
- 一行白色文本后，跟随一个蓝色的图标。这个蓝色图标可以响应点击操作，白色文本不响应点击操作。

上面功能有三个关键点：

- 文本可部分点击
- 可显示富文本
- 文本后可设置图标

考察了一番，最终决定使用 SpannableString 实现图文混排、文本变色，以及变色文本、图标可点击。

Android 中如果想要 TextView 显示富文本，可以使用 SpannableString，SpannableString可以设置 xxxSpan，实现不同效果的文本，以及图文混合显示。但是有几个点比较坑：

- Android SDK 提供的 URLSpan，虽然可以点击，但是文本带有下划线。本问题中，富文本不需要下划线。故 URLSpan 不满足要求
- Android SDK 提供的 ImageSpan，可以实现文本中显示图片，但是不能响应点击操作。也不满足要求。

最终决定自定义 Span。自定义也不太复杂。

## 定义点击接口

点击接口定义如下，代表着点击能力。实现了这个接口，xxxSpan 就有了响应点击操作的能力。

```java
public interface IClickableSpan {
    /**
     * 自定义点击事件，配合 LinkMovementMethod 使用
     * */
    void onClick(View view);
}
```

## 自定义 ImageSpan

新增可点击的 ImageSpan，继承自 ImageSpan，用于显示图标。

```java
/**
 * 抽象类，点击操作在具体的实例处实现
 */
public abstract class ClickableImageSpan extends ImageSpan 
    implements IClickableSpan {
    public ClickableImageSpan(@NonNull Drawable drawable) {
        super(drawable);
    }

    @Override
    public int getSize(@NonNull Paint paint, CharSequence text, int start, int end, 
                       @Nullable Paint.FontMetricsInt fm) {
        Drawable drawable = getDrawable();

        if (fm != null) {
            // FontMetricsInt 不能使用方法自带的 fm，其现在没有值
            Paint.FontMetricsInt fmPaint = paint.getFontMetricsInt();
            if(fmPaint == null) {
                return drawable.getBounds().right;
            }
            // 文字行的高度（具体字符顶部到底部的真实高度）
            int fontH = fmPaint.descent - fmPaint.ascent;
            // 图片的高度
            int imageH = drawable.getIntrinsicHeight();

            // 如果图片的高度 <= 文本的高度,放大图片
            if (imageH < fontH) {
                // 如果是小图片，需要先放大图片，防止图片过小时，影响查看
                int srcWidth = drawable.getIntrinsicWidth();
                int srcHeight = drawable.getIntrinsicHeight();
                int destHeight = fmPaint.descent - fmPaint.ascent;
                int destWidth = (int)((float)destHeight / srcHeight * srcWidth);
                drawable.setBounds(0, 0, destWidth, destHeight);
            }

            // 如果图片的高度 > 文本的高度，则调整文本位置，相对于图片居中
            fm.ascent = fmPaint.ascent - (imageH - fontH) / 2;
            fm.top = fmPaint.ascent - (imageH - fontH) / 2;
            fm.bottom = fmPaint.descent + (imageH - fontH) / 2;
            fm.descent = fmPaint.descent + (imageH - fontH) / 2;
        }
	return drawable.getBounds().right;
    }
}
```

## 自定义 TextSpan

新增可点击的 TextSpan，继承自 ForegroundColorSpan，用于改变文本的颜色。

```java
/**
 * 抽象类，点击操作在具体的实例处实现
 */
public abstract class ClickableTextSpan extends ForegroundColorSpan 
    implements IClickableSpan {
    public ClickableTextSpan(int color) {
        super(color);
    }
}
```

## 自定义LinkMovementMethod

LinkMovementMethod 是我们在点击 Span 的时候响应，但系统原生的实现无法响应除 ClickableSpan 以外的其他 Span，故需要自定义，以放开限制。

```java
public class ClickableMovementMethod extends LinkMovementMethod {
    /** 
     * 单例类
     */
    private static ClickableMovementMethod sInstance;

    public static ClickableMovementMethod getInstance() {
        if (sInstance == null) {
            synchronized (ClickableMovementMethod.class) {
                if(sInstance == null) {
                    sInstance = new ClickableMovementMethod();
                }
            }
        }
        return sInstance;
    }

    @Override
    public boolean onTouchEvent(TextView widget, Spannable buffer, MotionEvent event) {
        // 以下代码参考自 LinkMovementMethod.onTouchEvent
        int action = event.getAction();
        if(action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_DOWN) {
            int x = (int) event.getX();
            int y = (int) event.getY();

            x -= widget.getTotalPaddingLeft();
            y -= widget.getTotalPaddingTop();

            x += widget.getScrollX();
            y += widget.getScrollY();

            Layout layout = widget.getLayout();
            int line = layout.getLineForVertical(y);
            int off = layout.getOffsetForHorizontal(line, x);

            // 关键代码，新增得到 IClickableSpan，处理自定义的点击操作
            // 代码写法参考自系统实现
            IClickableSpan[] clickSpans = buffer.getSpans(off, off, IClickableSpan.class);
            if(clickSpans != null && clickSpans.length > 0) {
                IClickableSpan link = clickSpans[0];
                if (action == MotionEvent.ACTION_UP) {
                    link.onClick(widget);
                } else {
                    Selection.setSelection(buffer, buffer.getSpanStart(link), 
                                           buffer.getSpanEnd(link));
                }
                return true;
            }
            return super.onTouchEvent(widget, buffer, event);
        }
        return super.onTouchEvent(widget, buffer, event);
    }
}
```

## 使用

自定义完了上述的几个类之后，就可以使用了。

```java
public void setView(final Info info) {
    if(info == null) {
        return;
    }
    SpannableString spannableString;
    StringBuilder srcText = new StringBuilder();
    // 添加文本
    builder.append(mContext.getString(stringResId));
    // 增加空格，防止可点击内容和提示文本靠的过于紧凑
    // 使用 Html 是因为 TextView 会对空格进行优化，多个空格时，只会显示一个空格
    builder.append(Html.fromHtml("&#160;&#160;"));
    // 文本末尾显示可点击的图标
    if(info.isIcon()) {
        // 添加一个字符 i，意为图标，最后会被替换成图片。
        // 此处添加这个字符的目的是防止数组下标越界
        srcText.append("i");
        spannableString = new SpannableString(srcText);
        Drawable drawable = mContext.getResources().getDrawable(R.drawable.icon);
        // IClickableSpan 具体实现的地方
        ClickableImageSpan imageSpan = new ClickableImageSpan(drawable) {
            @Override
            public void onClick(View view) {
                dealClickEvent(view, info);
            }
        };
        // 最后一个字符替换为图标
        spannableString.setSpan(imageSpan, srcText.length() - 1, 
                                srcText.length(), 
                                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
    } else {
        // 文本末尾显示可点击的文本
        String clickText = mContext.getResources().getString(R.string.click_text);
        spannableString = new SpannableString(srcText + clickText);
        // IClickableSpan 具体实现的地方
        ClickableTextSpan textSpan = new ClickableTextSpan(Color.BLUE) {
            @Override
            public void onClick(View view) {
                dealClickEvent(view, info);
            }
        };
        spannableString.setSpan(textSpan, srcText.length(), 
                                srcText.length() + clickText.length(),
				Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
    }
    // 设置 TextView
    tvHint.setMovementMethod(ClickableMovementMethod.getInstance());
    tvHint.setText(spannableString);
}
```

至此，功能就算完成了。自测一波，效果 OK。
