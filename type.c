#include <stdlib.h>
#include "type.h"

struct type *type_create(type_kind_t kind, struct param_list *params, struct type *subtype) {
	struct type *type = malloc(sizeof(struct type));
	type -> kind = kind;
	type -> params = params;
	type -> subtype = subtype;
	return type;
}

void type_print(struct type *t) {
	if(!t)
		return;
	switch(t->kind) {
		case TYPE_BOOLEAN:
			printf("boolean");
			break;
		case TYPE_CHARACTER:
			printf("character");
			break;
		case TYPE_INTEGER:
			printf("integer");
			break;
		case TYPE_STRING:
			printf("string");
			break;
		case TYPE_ARRAY:
			break;
		case TYPE_FUNCTION:
			printf("function ");
			type_print(t->subtype);
			printf(" (");
			param_list_print(t->params);
			printf(") ");
			break;
		case TYPE_VOID:
			printf("void");
			break;
	}
}
