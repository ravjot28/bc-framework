package cn.bc.acl.web.struts2;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Controller;

import cn.bc.acl.domain.AccessActor;
import cn.bc.acl.domain.AccessDoc;
import cn.bc.acl.service.AccessActorService;
import cn.bc.acl.service.AccessDocService;
import cn.bc.core.exception.ConstraintViolationException;
import cn.bc.core.exception.InnerLimitedException;
import cn.bc.core.exception.NotExistsException;
import cn.bc.core.exception.PermissionDeniedException;
import cn.bc.identity.service.ActorService;
import cn.bc.identity.web.SystemContext;
import cn.bc.identity.web.struts2.FileEntityAction;
import cn.bc.option.OptionConstants;
import cn.bc.option.service.OptionService;
import cn.bc.web.ui.html.page.ButtonOption;
import cn.bc.web.ui.html.page.PageOption;
import cn.bc.web.ui.json.Json;

/**
 * 访问控制表单Action
 * 
 * @author lbj
 * 
 */

@Scope(BeanDefinition.SCOPE_PROTOTYPE)
@Controller
public class AccessControlAction extends FileEntityAction<Long, AccessDoc> {
	private static final long serialVersionUID = 1L;
	private AccessDocService accessDocService;
	private AccessActorService accessActorService;
	private ActorService actorService;
	private OptionService optionService;

	public List<AccessActor> accessActor4List;// 访问者集合
	public String accessActors;// 保存访问者json字符串
	public Boolean isFromDoc = false;// 判断是否从对象中创建的配置
	public String showRole;//权限显示的配置 如"01"只显示查阅，"11"显示查阅和编辑按钮
	
	public List<Map<String, String>> categoryList;//所属模块可选列
	

	@Autowired
	public void setOptionService(OptionService optionService) {
		this.optionService = optionService;
	}
	
	@Autowired
	public void setAccessDocService(AccessDocService accessDocService) {
		this.setCrudService(accessDocService);
		this.accessDocService = accessDocService;
	}

	@Autowired
	public void setAccessActorService(AccessActorService accessActorService) {
		this.accessActorService = accessActorService;
	}

	@Autowired
	public void setActorService(ActorService actorService) {
		this.actorService = actorService;
	}

	@Override
	public boolean isReadonly() {
		SystemContext context = (SystemContext) this.getContext();
		// 配置权限：访问监控管理员或系统管理员
		return !context.hasAnyRole(getText("key.role.bc.acl"),
				getText("key.role.bc.admin"));
	}

	@Override
	protected void buildFormPageButtons(PageOption pageOption, boolean editable) {
		if (!this.isReadonly()) {
			pageOption.addButton(new ButtonOption("查看"
					+ getText("accessHistroy"), null,
					"bc.accessControlForm.history"));

			if (editable) {
				pageOption
						.addButton(new ButtonOption(
								isFromDoc ? getText("label.ok")
										: getText("label.save"), null,
								"bc.accessControlForm.save"));
			}
		}

	}

	@Override
	protected PageOption buildFormPageOption(boolean editable) {
		return super.buildFormPageOption(editable).setWidth(500)
				.setMinHeight(200).setMinWidth(300).setHeight(500).setMaxHeight(600);
	}

	@Override
	protected void initForm(boolean editable) throws Exception {
		super.initForm(editable);
		if (!this.getE().isNew()) {
			this.accessActor4List = this.accessActorService.findByPid(this
					.getE().getId());
		}
		
		// 批量加载可选项列表
		Map<String, List<Map<String, String>>> optionItems = optionService
				.findOptionItemByGroupKeys(new String[] {OptionConstants.OPERATELOG_PTYPE});
		
		categoryList = optionItems.get(OptionConstants.OPERATELOG_PTYPE);
	}

	// 解释访问者字符串为对象
	private List<AccessActor> parse() {
		List<AccessActor> accessActors = new ArrayList<AccessActor>();
		try {
			if (this.accessActors != null && this.accessActors.length() > 0) {
				AccessActor accessActor;
				JSONArray jsons = new JSONArray(this.accessActors);
				JSONObject json;
				for (int i = 0; i < jsons.length(); i++) {
					json = jsons.getJSONObject(i);
					accessActor = new AccessActor();
					accessActor.setActor(this.actorService.load(json
							.getLong("aid")));
					accessActor.setOrderNo(json.getInt("orderNo"));
					accessActor.setRole(json.getString("role"));
					accessActors.add(accessActor);
				}
			}

		} catch (JSONException e) {
			logger.error(e.getMessage(), e);
			try {
				throw e;
			} catch (JSONException e1) {
				e1.printStackTrace();
			}
		}

		return accessActors;
	}

	@Override
	public String save() throws Exception {
		this.beforeSave(this.getE());
		this.accessDocService.save4AccessActors(this.getE(), this.parse());
		this.afterSave(this.getE());
		return "saveSuccess";
	}

	@Override
	public String delete() throws Exception {
		Json _json = new Json();
		try {
			// 删除一条
			this.accessDocService.delete(this.getId());
			_json.put("success", true);
			_json.put("msg", getText("form.delete.success"));
			json = _json.toString();
			return "json";
		} catch (PermissionDeniedException e) {
			// 执行没有权限的操作
			_json.put("msg", getDeleteExceptionMsg(e));
			_json.put("e", e.getClass().getSimpleName());
		} catch (InnerLimitedException e) {
			// 删除内置对象
			_json.put("msg", getDeleteExceptionMsg(e));
			_json.put("e", e.getClass().getSimpleName());
		} catch (NotExistsException e) {
			// 执行没有权限的操作
			_json.put("msg", getDeleteExceptionMsg(e));
			_json.put("e", e.getClass().getSimpleName());
		} catch (ConstraintViolationException e) {
			// 违反约束关联引发的异常
			_json.put("msg", getDeleteExceptionMsg(e));
			_json.put("e", e.getClass().getSimpleName());
		} catch (Exception e) {
			// 其他异常
			dealOtherDeleteException(_json, e);
		}
		_json.put("success", false);
		json = _json.toString();
		return "json";
	}

	public String docId;
	public String docType;
	public String docName;

	// 从对象中发起的配置
	public String configureFromDoc() throws Exception {
		// 初始化表单的配置信息
		this.formPageOption = buildFormPageOption(true);
		AccessDoc e = this.accessDocService.load(this.docId, this.docType);
		if (e == null) {
			e = this.getCrudService().create();
			this.afterCreate(e);
			e.setDocId(docId);
			e.setDocType(docType);
			e.setDocName(docName);
			this.setE(e);
		} else {
			this.setE(e);
		}

		initForm(true);

		return SUCCESS;
	}

}