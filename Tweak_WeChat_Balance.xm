#import <substrate.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
// #import "src/NSObject+LogWriteToFile.h"

@interface NSObject (LogWriteToFile)
- (void)writeToFileWithClass;
- (id)idFromObject:(nonnull id)object;
- (NSDictionary *)dictionaryFromModel;
- (void)showAlertView:(NSString *)message;
@end

@implementation NSObject (LogWriteToFile)

- (void)writeToFileWithClass{
    
    NSDictionary *dictionary = [self dictionaryFromModel];
    
    NSString * allClassMessage = [NSString stringWithFormat:@"%@",dictionary];
    NSString * writePath = [NSString stringWithFormat:@"/var/mobile/%@.txt",NSStringFromClass([self class])];
    [allClassMessage writeToFile:writePath atomically:NO encoding:4 error:NULL];
}

- (NSDictionary *)dictionaryFromModel
{
    unsigned int count = 0;
    
    Ivar * ivars = class_copyIvarList([self class], &count);
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
        id value = [self valueForKey:key];
        
        //only add it to dictionary if it is not nil
        if (key && value) {
            if ([value isKindOfClass:[NSString class]]
                || [value isKindOfClass:[NSNumber class]]) {
                [dict setObject:value forKey:key];
            }else if ([value isKindOfClass:[NSArray class]]
                     || [value isKindOfClass:[NSDictionary class]]) {
                // 数组类型或字典类型
                [dict setObject:[self idFromObject:value] forKey:key];
            }else{
                if (![value isMemberOfClass:[NSObject class]]) {
                    [dict setObject:[value dictionaryFromModel] forKey:key];
                }

            }
        } else if (key && value == nil) {
            // 如果当前对象该值为空，设为nil。在字典中直接加nil会抛异常，需要加NSNull对象
            [dict setObject:[NSNull null] forKey:key];
        }
    }
    
    free(ivars);
    return dict;
}

- (id)idFromObject:(nonnull id)object
{
    if ([object isKindOfClass:[NSArray class]]) {
        if (object != nil && [object count] > 0) {
            NSMutableArray *array = [NSMutableArray array];
            for (id obj in object) {
                // 基本类型直接添加
                if ([obj isKindOfClass:[NSString class]]
                    || [obj isKindOfClass:[NSNumber class]]) {
                    [array addObject:obj];
                }
                // 字典或数组需递归处理
                else if ([obj isKindOfClass:[NSDictionary class]]
                         || [obj isKindOfClass:[NSArray class]]) {
                    [array addObject:[self idFromObject:obj]];
                }
                // model转化为字典
                else {
                    [array addObject:[obj dictionaryFromModel]];
                }
            }
            return array;
        }
        else {
            return object ? : [NSNull null];
        }
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        if (object && [[object allKeys] count] > 0) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            for (NSString *key in [object allKeys]) {
                // 基本类型直接添加
                if ([object[key] isKindOfClass:[NSNumber class]]
                    || [object[key] isKindOfClass:[NSString class]]) {
                    [dic setObject:object[key] forKey:key];
                }
                // 字典或数组需递归处理
                else if ([object[key] isKindOfClass:[NSArray class]]
                         || [object[key] isKindOfClass:[NSDictionary class]]) {
                    [dic setObject:[self idFromObject:object[key]] forKey:key];
                }
                // model转化为字典
                else {
                    [dic setObject:[object[key] dictionaryFromModel] forKey:key];
                }
            }
            return dic;
        }
        else {
            return object ? : [NSNull null];
        }
    }
    
    return [NSNull null];
}


- (void)showAlertView:(NSString *)message{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:message message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

@end

@interface WCPayTransferMoneyData:NSObject
@end

@interface WCPaySwitchInfo:NSObject
@end
//零钱通
@interface WCPayLQTInfo:NSObject
@end


@interface WCPayBindCardListApplyNewCardInfo:NSObject
@end

@interface WCPayPayMenuArrayInfo:NSObject
@end

@interface WCPayLoanEntryInfo:NSObject
@end

@interface WCPayF2FControlData:NSObject
@end

@interface WCPayHoneyPayControlData:NSObject
@end

@interface WCPayLqtCellInfo:NSObject
@property(retain, nonatomic) NSString *lqt_wording;
@end

@interface WCPayUserInfo:NSObject
@property(retain, nonatomic) WCPayLqtCellInfo *lqtCellInfo;
@end

//余额支付
@interface WCPayBalanceInfo:NSObject
@property(nonatomic) unsigned long long m_uiAvailableBalance;
@property(nonatomic) unsigned long long m_uiFetchBalance; // @synthesize m_uiFetchBalance;
@property(nonatomic) unsigned long long m_uiTotalBalance;
@end

@interface WCPayControlData:NSObject
@property(retain, nonatomic) WCPayTransferMoneyData *transferMoneyData; 
@property(retain, nonatomic) WCPayUserInfo *m_structUserInfo;
@property(retain, nonatomic) WCPaySwitchInfo *m_structSwitchInfo;
@property(retain, nonatomic) WCPayLQTInfo *m_structLqtInfo;
@property(retain, nonatomic) WCPayBalanceInfo *m_structBalanceInfo;
@property(retain, nonatomic) WCPayBindCardListApplyNewCardInfo *m_payApplyNewCardInfo;
@property(retain, nonatomic) WCPayPayMenuArrayInfo *m_payMenuArrayInfo;
@property(retain, nonatomic) WCPayLoanEntryInfo *m_loanEntryInfo;
@property(retain, nonatomic) WCPayF2FControlData *m_f2fControlData;
@property(retain, nonatomic) WCPayHoneyPayControlData *honeyPayData;
@end


@interface WCBizMainViewController:UIViewController

@end


static long long canUsingMoney = 80000000;

%hook WCBizMainViewController

- (void)viewWillAppear:(BOOL)arg1{
    %orig;
    self.title = @"My Wallet";
    NSLog(@"aaaaa");
}

- (void)refreshViewWithPayControlData:(WCPayControlData *)arg1
{
    [arg1 writeToFileWithClass]; 
    arg1.m_structBalanceInfo.m_uiAvailableBalance = canUsingMoney;
    arg1.m_structBalanceInfo.m_uiTotalBalance = canUsingMoney;
    arg1.m_structBalanceInfo.m_uiFetchBalance = canUsingMoney;
    %orig;
}

%end

//微信
%hook WCPayBalanceDetailViewController

- (void)refreshViewWithData:(WCPayControlData *)arg1{
    arg1.m_structBalanceInfo.m_uiAvailableBalance = canUsingMoney;
    arg1.m_structBalanceInfo.m_uiTotalBalance = canUsingMoney;
    arg1.m_structBalanceInfo.m_uiFetchBalance = canUsingMoney;

    arg1.m_structUserInfo.lqtCellInfo.lqt_wording = @"￥1000000000";
    
	NSLog(@"WeChat:refreshViewWithData: %s,%@,",object_getClassName(arg1),arg1);
	%orig;
}

%end