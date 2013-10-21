package cn.bc.form.struts2;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.struts2.ServletActionContext;
import org.apache.struts2.interceptor.RequestAware;
import org.apache.struts2.interceptor.SessionAware;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Controller;

import cn.bc.Context;
import cn.bc.core.util.JsonUtils;
import cn.bc.core.util.TemplateUtils;
import cn.bc.docs.service.AttachService;
import cn.bc.docs.web.ui.html.AttachWidget;
import cn.bc.form.domain.Form;
import cn.bc.form.service.FormService;
import cn.bc.identity.service.IdGeneratorService;
import cn.bc.identity.web.SystemContext;
import cn.bc.template.service.TemplateService;
import cn.bc.web.ui.json.Json;

import com.opensymphony.xwork2.ActionSupport;

/**
 * 自定义表单CRUD入口Action
 * 
 * @author lbj
 * 
 */
@Scope(BeanDefinition.SCOPE_PROTOTYPE)
@Controller
public class CustomFormEntityAction extends ActionSupport implements
		SessionAware, RequestAware {
	private static final long serialVersionUID = 1L;
	protected Map<String, Object> session;
	protected Map<String, Object> request;
	public Long id; // 自定义表单的id
	public String ids; // 批量删除的id，多个id间用逗号连接
	public String html;// 后台生成的html页面
	private FormService formService;
	private TemplateService templateService;
	private IdGeneratorService idGeneratorService;
	private AttachService attachService;
	public AttachWidget attachsUI;

	/**
	 * 模板编码 如果含字符":"，则进行分拆，前面部分为编码， 后面部分为版本号，如果没有字符":"，将获取当前状态为正常的版本后格式化
	 */
	public String tpl;

	public void setRequest(Map<String, Object> request) {
		this.request = request;
	}
	
	public void setSession(Map<String, Object> session) {
		this.session = session;
	}

	@Autowired
	public void setFormService(FormService formService) {
		this.formService = formService;
	}

	@Autowired
	public void setAttachService(AttachService attachService) {
		this.attachService = attachService;
	}

	@Autowired
	public void setIdGeneratorService(IdGeneratorService idGeneratorService) {
		this.idGeneratorService = idGeneratorService;
	}

	@Autowired
	public void setTemplateService(TemplateService templateService) {
		this.templateService = templateService;
	}

	public Context getContext() {
		return (Context) this.session.get(Context.KEY);
	}

	public boolean isReadonly() {
		return false;
	}

	// 创建自定义表单
	public String create() throws Exception {
		// 根据模板编码，调用相应的模板处理后输出格式化好的前台表单HTML代码
		String content = this.templateService.getContent(this.tpl);
		List<String> keys = TemplateUtils.findMarkers(content);
		SystemContext context = (SystemContext) this.getContext();
		Map<String, Object> args = new HashMap<String, Object>();
		// 将模板班中的参数key替换为空值
		for (int i = 0; i < keys.size(); i++) {
				args.put(keys.get(i), "");
			
		}
		Json infoArgs = new Json();
		infoArgs.put("uid",
				this.idGeneratorService.next(Form.ATTACH_TYPE + ".uid"));
		infoArgs.put("authorId", context.getUserHistory().getId());
		infoArgs.put("fileDate", new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
				.format(Calendar.getInstance().getTime()));
		args.put("form_info", infoArgs.toString());
		this.html = TemplateUtils.format(content, args);
		return "page";
	}

	// 保存自定义表单
	public String save() throws Exception {

		return "page";
	}

	// 编辑自定义表单
	public String edit() throws Exception {
		// 根据自定义表单id，获取相应的自定义表单表单对象，根据表单字段参数格式化模板后生成的前台表单HTML代码
		// TODO

		return "page";
	}

	// 查看自定表单
	public String open() throws Exception {
		// 构建附件控件
		attachsUI = buildAttachsUI(false, true);
		return "page";
	}

	protected AttachWidget buildAttachsUI(boolean isNew, boolean forceReadonly) {
		/*
		 * // 构建附件控件 String ptype = "bulletin.main"; String puid =
		 * this.getE().getUid(); boolean readonly = forceReadonly ? true :
		 * this.isReadonly(); AttachWidget attachsUI =
		 * AttachWidget.defaultAttachWidget(isNew, readonly, isFlashUpload(),
		 * this.attachService, ptype, puid);
		 * 
		 * // 上传附件的限制 attachsUI.addExtension(getText("app.attachs.extensions"))
		 * .setMaxCount(Integer.parseInt(getText("app.attachs.maxCount")))
		 * .setMaxSize(Integer.parseInt(getText("app.attachs.maxSize")));
		 */
		return attachsUI;
	}

	/** 通过浏览器的代理判断多文件上传是否必须使用flash方式 */
	public static boolean isFlashUpload() {
		// TODO Opera;
		return isIE();
	}

	/**
	 * 判断客户端的浏览器是否是IE浏览器
	 * 
	 * @return
	 */
	public static boolean isIE() {
		return ServletActionContext.getRequest().getHeader("User-Agent")
				.toUpperCase().indexOf("MSIE") != -1;
	}
}
